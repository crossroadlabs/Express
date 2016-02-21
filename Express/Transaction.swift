//===--- Transaction.swift ------------------------------------------------===//
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
import ExecutionContext
import BrightFutures
import Result

public protocol TransactionType : DataConsumerType {
    func tryConsume(content:ContentType) -> Bool
    
    var action:Future<AbstractActionType, AnyError> {get}
    
    func selfProcess()
}

class Transaction<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType, E: ErrorType> : TransactionType {
    let app:Express
    let routeId:String
    let out:DataConsumerType
    let head:RequestHeadType
    let factory:RequestContent.Factory
    let content:Future<RequestContent.Factory.Content, AnyError>
    let actionPromise:Promise<AbstractActionType, AnyError>
    let action:Future<AbstractActionType, AnyError>
    let request:Promise<Request<RequestContent>, NoError>
    
    internal required init(app:Express, routeId:String, head:RequestHeadType, out:DataConsumerType) {
        self.app = app
        self.routeId = routeId
        self.out = out
        self.head = head
        self.factory = RequestContent.Factory(response: head)
        self.content = factory.content()
        self.actionPromise = Promise()
        self.action = actionPromise.future
        self.request = Promise<Request<RequestContent>, NoError>()
    }
    
    convenience init(app:Express, routeId:String, head:RequestHeadType, out:DataConsumerType, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) {
        self.init(app: app, routeId: routeId, head: head, out: out)
        content.onSuccess(ExecutionContext.user) { content in
            let request = Request<RequestContent>(head: head, body: content as? RequestContent)
            self.request.success(request)
            let action = handler(request)
            action.onSuccess { action in
                self.actionPromise.success(action)
            }
            action.onFailure { e in
                switch e {
                    case let e as AnyError: self.failAction(e.cause)
                    default: self.failAction(e)
                }
            }
        }
        content.onFailure { e in
            self.actionPromise.failure(AnyError(cause: e))
        }
    }
    
    func failAction(e:ErrorType) {
        self.actionPromise.failure(AnyError(cause: e))
    }
    
    func handleAction(action:Future<AbstractActionType, AnyError>) {
        action.onSuccess(ExecutionContext.action) { action in
            //yes we certainly have request here
            for request in self.request.future.value {
                self.processAction(action, request: request)
            }
        }
        action.onFailure { e in
            //yes, we always have at least the default error handler
            let next = self.app.errorHandler.handle(e)!
            
            //FIXME: get the request from intermediate action somehow as well, it could have changed
            for request in self.request.future.value {
                self.processAction(next, request: request)
            }
        }
    }
    
    func selfProcess() {
        handleAction(action)
    }
    
    func processAction<C : ConstructableContentType>(action:AbstractActionType, request:Request<C>) {
        switch action {
            case let flushableAction as FlushableAction: flushableAction.flushTo(out)
            case let intermediateAction as IntermediateActionType:
                let act = intermediateAction.nextAction(app, routeId: routeId, request: request, out: out)
                //FIXME: get the request from intermediate action somehow as well, it could have changed
                handleAction(act)
            default:
                print("wierd action... can do nothing with it")
        }
    }
    
    func tryConsume(content:ContentType) -> Bool {
        return factory.tryConsume(content)
    }
    
    func consume(data:Array<UInt8>) -> Future<Void, AnyError> {
        return factory.consume(data)
    }
    
    func dataEnd() throws {
        try factory.dataEnd()
    }
}

typealias TransactionFactory = (RequestHeadType, DataConsumerType)->TransactionType