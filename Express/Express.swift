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
    
    func handleInternal<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType, E: ErrorType>(matcher:UrlMatcherType, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) -> Void {
        
        let routeId = NSUUID().UUIDString
        
        let factory:TransactionFactory = { head, out in
            return Transaction(app: self, routeId: routeId, head: head, out: out, handler: handler)
        }
        
        let route = Route(id: routeId, matcher: matcher, factory: factory)
        
        routes.append(route)
    }
    
    func handleInternal<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(matcher:UrlMatcherType, handler:Request<RequestContent> throws -> Action<ResponseContent>) -> Void {
        
        handleInternal(matcher) { request in
            //execute synchronous request aside from main queue (on a user queue)
            future(ExecutionContext.user) {
                return try handler(request)
            }
        }
    }
}

public extension Express {

    //sync
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(matcher:UrlMatcherType, handler:Request<RequestContent> throws -> Action<ResponseContent>) -> Void {
        handleInternal(matcher, handler: handler)
    }
    
    //async
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType, E: ErrorType>(matcher:UrlMatcherType, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) -> Void {
        handleInternal(matcher, handler: handler)
    }
    
    //action
    func handle<ResponseContent : FlushableContentType>(matcher:UrlMatcherType, action:Action<ResponseContent>) -> Void {
        return handle(matcher) { (request:Request<AnyContent>) -> Action<ResponseContent> in
            return action
        }
    }
}

