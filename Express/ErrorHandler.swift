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
    func handle(e:ErrorType) -> AbstractActionType?
}

public typealias ErrorHandlerFunction = ErrorType -> AbstractActionType?

class DefaultErrorHandler : ErrorHandlerType {
    func handle(e:ErrorType) -> AbstractActionType? {
        let errorName = Mirror(reflecting: e).description
        let description = "Internal Server Error\n\n" + errorName
        return Action<AnyContent>.internalServerError(description)
    }
}

class FunctionErrorHandler : ErrorHandlerType {
    let fun:ErrorHandlerFunction
    
    init(fun:ErrorHandlerFunction) {
        self.fun = fun
    }
    
    func handle(e:ErrorType) -> AbstractActionType? {
        return fun(e)
    }
}

internal let defaultErrorHandler = DefaultErrorHandler()

public class AggregateErrorHandler : ErrorHandlerType {
    internal var handlers:Array<ErrorHandlerType> = []
    
    init() {
        register { e in
            //this is the only way to check. Otherwise it will just always tall-free bridge to NSError
            if e.dynamicType == NSError.self {
                //stupid autobridging
                switch e {
                case let e as NSError:
                    return Action<AnyContent>.internalServerError(e.description)
                default: return nil
                }
            } else {
                return nil
            }
        }
        register(ExpressErrorHandler)
    }
    
    public func register(handler: ErrorHandlerType) {
        handlers.insert(handler, atIndex: 0)
    }
    
    public func register(f: ErrorHandlerFunction) {
        register(FunctionErrorHandler(fun: f))
    }
    
    public func register<E: ErrorType>(f:E -> AbstractActionType?) {
        register { e in
            guard let e = e as? E else {
                return nil
            }
            return f(e)
        }
    }
    
    public func handle(e:ErrorType) -> AbstractActionType? {
        for handler in handlers {
            if let action = handler.handle(e) {
                return action
            }
        }
        return defaultErrorHandler.handle(e)
    }
}