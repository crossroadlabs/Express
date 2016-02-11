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
import BrightFutures
import CPThread

private class ServerParams {
    let promise: Promise<Void, NoError>
    let port: UInt16
    let router:RouterType
    
    init(promise: Promise<Void, NoError>, port: UInt16, router: RouterType) {
        self.promise = promise
        self.port = port
        self.router = router
    }
}

private class ResponseDataConsumer : ResponseHeadDataConsumerType {
    let sock:EVHTPRequest
    var buffer: EVHTPBuffer?
    
    init(sock: EVHTPRequest) {
        self.sock = sock
        self.buffer = nil
    }
    
    func consume(head: HttpResponseHeadType) -> Future<Void, AnyError> {
        //TODO: handle errors if any
        if let h = head as? HttpResponseHead {
            buffer = EVHTP.start_response(sock, headers: h.headers, status: h.status)
        } else {
            buffer = EVHTP.start_response(sock, headers: Dictionary<String, String>(), status: head.status)
        }
        return Future(value: ())
    }
    
    func consume(data:Array<UInt8>) -> Future<Void, AnyError> {
        //TODO: handle errors if any
        buffer?.write(data)
        return Future(value: ())
    }
    
    func dataEnd() throws {
        //TODO: handle errors if any
        EVHTP.finish_response(sock, buffer: buffer!)
        buffer = nil
    }
}

private func handle_request(req: EVHTPRequest, serv:ServerParams) {
    //TODO: implement request data parsing
    
    let info = EVHTP.get_request_info(req)
    let head = RequestHead(method: info.method, version: info.version, remoteAddress: info.remoteIp, secure: info.scheme == "HTTPS", uri: info.uri, path: info.path, query: info.query, headers: info.headers, params: Dictionary())
    let os = ResponseDataConsumer(sock: req)
    
    guard let routeTuple = serv.router.firstRoute(head) else {
        //TODO: implement page not found (throw exception?, see other places)
        print("Route not found for request: ", head.path)
        return
    }
    
    let route = routeTuple.0
    let header = head.withParams(routeTuple.1)
    
    let transaction = route.factory(header, os)
    transaction.selfProcess()
    EVHTP.read_data(req, cb: { data in
        if data.count > 0 {
            //TODO: handle consumption success or error
            transaction.consume(data)
        } else {
            //TODO: handle errors (for now silencing it with try!)
            try! transaction.dataEnd()
        }
        return true
    })
}

private func server_thread(pm: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
    let serv = Unmanaged<ServerParams>.fromOpaque(COpaquePointer(pm)).takeRetainedValue()
    let base = EVHTP.create_base()
    let htp_serv = EVHTP.create_htp(base)
    EVHTP.bind_address(htp_serv, host: "0.0.0.0", port: serv.port)
    
    EVHTP.add_general_route(htp_serv) { (req: EVHTPRequest) -> () in
        handle_request(req, serv: serv)
    }
    
    EVHTP.start_event(base).onSuccess {
        serv.promise.success()
    }
    
    EVHTP.start_server_loop(base)
    return nil
}

class HttpServer : ServerType {
    let router:RouterType
    let thread: UnsafeMutablePointer<pthread_t>
    
    func start(port:UInt16) -> Future<Void, NoError> {
        let params = ServerParams(promise: Promise<Void, NoError>(), port: port, router: router)
        
        pthread_create(thread, nil, server_thread, UnsafeMutablePointer<Void>(Unmanaged.passRetained(params).toOpaque()))
        return params.promise.future
    }
    
    required init(router:RouterType) {
        self.router = router
        self.thread = UnsafeMutablePointer<pthread_t>.alloc(1)
    }
    deinit {
        self.thread.destroy()
        self.thread.dealloc(1)
    }
}