//===--- ErrorHandler.swift -----------------------------------------------===//
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
import Future

public protocol ErrorHandlerType {
    func handle(e:Error) -> AbstractActionType?
}

public typealias ErrorHandlerFunction = (Error) -> AbstractActionType?

class DefaultErrorHandler : ErrorHandlerType {
    func handle(e:Error) -> AbstractActionType? {
        let errorName = Mirror(reflecting: e).description
        let description = "Internal Server Error\n\n" + errorName
        return Action<AnyContent>.internalServerError(description: description)
    }
}

class FunctionErrorHandler : ErrorHandlerType {
    let fun:ErrorHandlerFunction
    
    init(fun:@escaping ErrorHandlerFunction) {
        self.fun = fun
    }
    
    convenience init<E : Error>(fun: @escaping (E) -> AbstractActionType?) {
        self.init { e -> AbstractActionType? in
            guard let e = e as? E else {
                return nil
            }
            return fun(e)
        }
    }
    
    func handle(e:Error) -> AbstractActionType? {
        return fun(e)
    }
}

internal let defaultErrorHandler = DefaultErrorHandler()

public class AggregateErrorHandler : ErrorHandlerType {
    internal var handlers:Array<ErrorHandlerType> = []
    
    init() {
        register { e in
            //this is the only way to check. Otherwise it will just always tall-free bridge to NSError
            if type(of: e) == NSError.self {
                //stupid autobridging
                switch e {
                case let e as NSError:
                    return Action<AnyContent>.internalServerError(description: e.description)
                default: return nil
                }
            } else {
                return nil
            }
        }
        register(ExpressErrorHandler)
    }
    
    public func register(handler: ErrorHandlerType) {
        handlers.insert(handler, at: 0)
    }
    
    public func handle(e:Error) -> AbstractActionType? {
        for handler in handlers {
            if let action = handler.handle(e: e) {
                return action
            }
        }
        return defaultErrorHandler.handle(e: e)
    }
}

//API sugar

public extension AggregateErrorHandler {
    public func register(_ f: @escaping ErrorHandlerFunction) {
        register(handler: FunctionErrorHandler(fun: f))
    }
    
    public func register<Content : FlushableContentType>(_ f: @escaping (Error) -> Action<Content>?) {
        register(handler: FunctionErrorHandler(fun: f))
    }
    
    public func register(_ f: @escaping (Error) -> Action<AnyContent>?) {
        register(handler: FunctionErrorHandler(fun: f))
    }
    
    public func register<E: Error>(_ f:@escaping (E) -> AbstractActionType?) {
        register(handler: FunctionErrorHandler(fun: f))
    }
    
    public func register<Content : FlushableContentType, E: Error>(_ f:@escaping (E) -> Action<Content>?) {
        register(handler: FunctionErrorHandler(fun: f))
    }
    
    public func register<E: Error>(_ f:@escaping (E) -> Action<AnyContent>?) {
        register(handler: FunctionErrorHandler(fun: f))
    }
}
