//===--- HttpServer.swift -------------------------------------------------===//
//
//Copyright (c) 2015-2016 Daniel Leping (dileping)
//
//This file is part of Swift Express.
//
//Swift Express is free software: you can redistribute it and/or modify
//it under the terms of the GNU Lesser General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//Swift Express is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with Swift Express.  If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//

import Foundation
import Result
import Future
#if os(Linux)
    import Glibc
#endif
import ExecutionContext

private class ServerParams {
    let port: UInt16
    let app:Express
    
    init(port: UInt16, app: Express) {
        self.port = port
        self.app = app
    }
}

private class ResponseDataConsumer : ResponseHeadDataConsumerType {
    let sock:EVHTPRequest
    var buffer: EVHTPBuffer?
    
    init(sock: EVHTPRequest) {
        self.sock = sock
        self.buffer = nil
    }
    
    func consume(head: HttpResponseHeadType) -> Future<Void> {
        return future(context: ExecutionContext.network) {
            //TODO: handle errors if any
            if let h = head as? HttpResponseHead {
                self.buffer = EVHTP.start_response(req: self.sock, headers: h.headers, status: h.status)
            } else {
                self.buffer = EVHTP.start_response(req: self.sock, headers: Dictionary<String, String>(), status: head.status)
            }
        }
    }
    
    func consume(data:Array<UInt8>) -> Future<Void> {
        return future(context: ExecutionContext.network) {
            //TODO: handle errors if any
            self.buffer?.write(data: data)
        }
    }
    
    func dataEnd() throws {
        ExecutionContext.network.async {
            //TODO: handle errors if any
            EVHTP.finish_response(req: self.sock, buffer: self.buffer!)
            self.buffer = nil
        }
    }
}

private func handle_request(req: EVHTPRequest, serv:ServerParams) {
    //TODO: implement request data parsing
    
    let info = EVHTP.get_request_info(req: req)
    let head = RequestHead(app: serv.app, method: info.method, version: info.version, remoteAddress: info.remoteIp, secure: info.scheme == "HTTPS", uri: info.uri, path: info.path, query: info.query, headers: info.headers, params: Dictionary())
    let os = ResponseDataConsumer(sock: req)
    
    let routeTuple = serv.app.firstRoute(request: head)
    let transaction = routeTuple.map {
        ($0.0, head.withParams(params: $0.1, app: serv.app))
    }.map { ( route, header) in
        route.factory(header, os)
    }
        
        
    /*    .getOrElse(Transaction(app: serv.app, routeId: "", head: head, out: os))
    
    let route = routeTuple.0
    let header = head.withParams(routeTuple.1)*/
    
    if let transaction = transaction {
        transaction.selfProcess()
        EVHTP.read_data(req: req, cb: { data in
            if data.count > 0 {
                //TODO: handle consumption success or error
                transaction.consume(data: data)
            } else {
                //TODO: handle errors (for now silencing it with try!)
                try! transaction.dataEnd()
            }
            return true
        })
    } else {
        let transaction = Transaction<AnyContent, AnyContent>(app: serv.app, routeId: "", head: head, out: os)
        let action = future(context: immediate) { () throws -> AbstractActionType in
            throw ExpressError.RouteNotFound(path: head.path)
        }
        transaction.handleAction(action: action, request: Optional<Request<AnyContent>>.none)
        try! transaction.dataEnd()
    }
}

private func setup_server(params serv:ServerParams) -> Bool {
    let base = ExecutionContext.network.base
    
    let htp_serv = EVHTP.create_htp(base: base)
    let bound = EVHTP.bind_address(htp: htp_serv, host: "0.0.0.0", port: serv.port)
    EVHTP.add_general_route(htp: htp_serv) { (req: EVHTPRequest) -> () in
        handle_request(req: req, serv: serv)
    }
    return bound == 0
}

class HttpServer : ServerType {
    let port:UInt16
    let app:Express
    let thread: UnsafeMutablePointer<pthread_t?>
    
    func start() -> Future<ServerType> {
        let params = ServerParams(port: port, app: app)
        return future(context:ExecutionContext.network) {
            setup_server(params: params)
        }.filter {$0}.map {_ in self}
    }
    
    required init(app:Express, port:UInt16) {
        self.port = port
        self.app = app
        self.thread = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
    }
    
    deinit {
        self.thread.deinitialize()
        self.thread.deallocate(capacity: 1)
    }
}
