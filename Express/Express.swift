//===--- Express.swift ----------------------------------------------------===//
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

public func express() -> Express {
    return Express()
}

public class Express : RouterType {
    var routes:Array<RouteType> = []
    var server:ServerType?
    public let views:Views = Views()
    public let errorHandler:AggregateErrorHandler = AggregateErrorHandler()
    
    func routeForId(id:String) -> RouteType? {
        //TODO: hash it
        return routes.findFirst { route in
            route.id == id
        }
    }
    
    func handleInternal<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType, E: ErrorType>(method:String, path:String, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) -> Void {
        
        let routeId = NSUUID().UUIDString
        
        let factory:TransactionFactory = { head, out in
            return Transaction(app: self, routeId: routeId, head: head, out: out, handler: handler)
        }
        
        //TODO: handle exception properly
        let matcher = try! RegexUrlMatcher(method: method, pattern: path)
        let route = Route(id: routeId, matcher: matcher, factory: factory)
        
        routes.append(route)
    }
    
    func handleInternal<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, path:String, handler:Request<RequestContent> throws -> Action<ResponseContent>) -> Void {
        
        handleInternal(method, path: path) { request in
            //execute synchronous request aside from main queue (on a user queue)
            future(ExecutionContext.user) {
                return try handler(request)
            }
        }
    }
}

public extension Express {

    //sync
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, path:String, handler:Request<RequestContent> throws -> Action<ResponseContent>) -> Void {
        handleInternal(method, path: path, handler: handler)
    }
    
    func get<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:Request<RequestContent> throws -> Action<ResponseContent>) -> Void {
        self.handle(HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:Request<RequestContent> throws -> Action<ResponseContent>) -> Void {
        self.handle(HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    
    //async
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType, E: ErrorType>(method:String, path:String, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) -> Void {
        handleInternal(method, path: path, handler: handler)
    }
    
    func get<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType, E: ErrorType>(path:String, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) -> Void {
        handleInternal(HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType, E: ErrorType>(path:String, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) -> Void {
        handleInternal(HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    //action
    func handle<ResponseContent : FlushableContentType>(method:String, path:String, action:Action<ResponseContent>) -> Void {
        return handle(method, path: path) { request in
            return action
        }
    }
    
    func get<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        return get(path) { request in
            return action
        }
    }
    
    func post<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        return post(path) { request in
            return action
        }
    }
}

