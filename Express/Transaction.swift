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
        content.onSuccess(ExecutionContext.user) { content in
            let request = Request<RequestContent>(app: app, head: head, body: content as? RequestContent)
            self.request.success(request)
        }
        content.onFailure { e in
            self.actionPromise.failure(AnyError(cause: e))
        }
    }
    
    convenience init(app:Express, routeId:String, head:RequestHeadType, out:DataConsumerType, handler:Request<RequestContent> -> Future<Action<ResponseContent>, E>) {
        self.init(app: app, routeId: routeId, head: head, out: out)
        request.future.onSuccess { request in
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
    }
    
    func failAction(e:ErrorType) {
        self.actionPromise.failure(AnyError(cause: e))
    }
    
    func handleActionWithRequest<C : ConstructableContentType>(actionAndRequest:Future<(AbstractActionType, Request<C>?), AnyError>) {
        actionAndRequest.onComplete { result in
            let action = Future(result: result.map {$0.0})
            self.handleAction(action, request: result.value?.1)
        }
    }
    
    func handleAction<C : ConstructableContentType>(action:Future<AbstractActionType, AnyError>, request:Request<C>?) {
        action.onSuccess(ExecutionContext.action) { action in
            if let request = request {
                self.processAction(action, request: request)
            } else {
                //yes we certainly have request here
                for request in self.request.future.value {
                    self.processAction(action, request: request)
                }
            }
        }
        action.onFailure { e in
            //yes, we always have at least the default error handler
            let next = self.app.errorHandler.handle(e)!
            
            if let request = request {
                self.processAction(next, request: request)
            } else {
                self.request.future.onSuccess { request in
                    self.processAction(next, request: request)
                }
            }
        }
    }
    
    func selfProcess() {
        handleAction(action, request: Optional<Request<RequestContent>>.None)
    }
    
    func processAction<C : ConstructableContentType>(action:AbstractActionType, request:Request<C>) {
        switch action {
            case let flushableAction as FlushableAction: flushableAction.flushTo(out)
            case let intermediateAction as IntermediateActionType:
                let actAndReq = intermediateAction.nextAction(request)
                handleActionWithRequest(actAndReq)
            case let selfSufficientAction as SelfSufficientActionType:
                selfSufficientAction.handle(app, routeId: routeId, request: request, out: out).onFailure { e in
                    let action = Future<AbstractActionType, AnyError>(error: AnyError(cause: e))
                    self.handleAction(action, request: request)
                }
            default:
                //TODO: handle server error
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