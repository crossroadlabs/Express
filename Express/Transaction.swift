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

import Result
import Boilerplate
import ExecutionContext
import Future

public protocol TransactionType : DataConsumerType {
    func tryConsume(content:ContentType) -> Bool
    
    var action:Future<AbstractActionType> {get}
    
    func selfProcess()
}

class Transaction<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType> : TransactionType {
    let app:Express
    let routeId:String
    let out:DataConsumerType
    let head:RequestHeadType
    let factory:RequestContent.Factory
    let content:Future<RequestContent.Factory.Content>
    let actionPromise:Promise<AbstractActionType>
    let action:Future<AbstractActionType>
    let request:Promise<Request<RequestContent>>
    var _request:Request<RequestContent>? = nil
    
    internal required init(app:Express, routeId:String, head:RequestHeadType, out:DataConsumerType) {
        self.app = app
        self.routeId = routeId
        self.out = out
        self.head = head
        self.factory = RequestContent.Factory(response: head)
        self.content = factory.content()
        self.actionPromise = Promise()
        self.action = actionPromise.future
        self.request = Promise<Request<RequestContent>>()
        content.onSuccess(ExecutionContext.user) { content in
            let request = Request<RequestContent>(app: app, head: head, body: content as? RequestContent)
            try! self.request.success(request)
        }
        content.onFailure { e in
            try! self.actionPromise.fail(e)
        }
    }
    
    convenience init(app:Express, routeId:String, head:RequestHeadType, out:DataConsumerType, handler:Request<RequestContent> -> Future<Action<ResponseContent>>) {
        self.init(app: app, routeId: routeId, head: head, out: out)
        request.future.onSuccess { request in
            self._request = request
            let action = handler(request)
            action.onSuccess { action in
                try! self.actionPromise.success(action)
            }
            action.onFailure { e in
                try! self.failAction(e)
            }
        }
    }
    
    func failAction(e:ErrorType) throws {
        try self.actionPromise.fail(e)
    }
    
    func handleActionWithRequest<C : ConstructableContentType>(actionAndRequest:Future<(AbstractActionType, Request<C>?)>) {
        actionAndRequest.onComplete { (result:Result<(AbstractActionType, Request<C>?), AnyError>) in
            let action = Future(result: result.map {$0.0})
            self.handleAction(action, request: result.value?.1)
        }
    }
    
    func handleAction<C : ConstructableContentType>(action:Future<AbstractActionType>, request:Request<C>?) {
        action.onSuccess(ExecutionContext.action) { action in
            if let request = request {
                self.processAction(action, request: request)
            } else {
                //yes we certainly have request here
                self.processAction(action, request: self._request!)
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
                    let action = Future<AbstractActionType>(error: e)
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
    
    func consume(data:Array<UInt8>) -> Future<Void> {
        return factory.consume(data)
    }
    
    func dataEnd() throws {
        try factory.dataEnd()
    }
}

typealias TransactionFactory = (RequestHeadType, DataConsumerType)->TransactionType