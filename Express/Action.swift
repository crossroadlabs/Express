//===--- Action.swift -----------------------------------------------------===//
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

public protocol AbstractActionType {
}

public protocol ActionType : AbstractActionType {
    typealias Content
}

public protocol FlushableAction : AbstractActionType, FlushableType {
}

public protocol IntermediateActionType : AbstractActionType {
    func nextAction<RequestContent : ConstructableContentType>(app:Express, routeId:String, request:Request<RequestContent>, out:DataConsumerType) -> Future<AbstractActionType, AnyError>
}

public class Action<C : FlushableContentType> : ActionType, AbstractActionType {
    public typealias Content = C
}

class ResponseAction<C : FlushableContentType> : Action<C>, FlushableAction {
    let response:Response<C>
    
    init(response:Response<C>) {
        self.response = response
    }
    
    func flushTo(out: DataConsumerType) -> Future<Void, AnyError> {
        return response.flushTo(out)
    }
}

class RenderAction<C : FlushableContentType> : Action<C>, IntermediateActionType {
    let view:String
    let context:AnyObject?
    
    init(view:String, context:AnyObject?) {
        self.view = view
        self.context = context
    }
    
    func nextAction<RequestContent : ConstructableContentType>(app:Express, routeId:String, request:Request<RequestContent>, out:DataConsumerType) -> Future<AbstractActionType, AnyError> {
        return app.views.render(view, context: context)
    }
}

class ChainAction<C : FlushableContentType, ReqC: ConstructableContentType> : Action<C>, IntermediateActionType {
    let request:Request<ReqC>?
    
    init(request:Request<ReqC>? = nil) {
        self.request = request
    }
    
    func nextAction<RequestContent : ConstructableContentType>(app:Express, routeId:String, request:Request<RequestContent>, out:DataConsumerType) -> Future<AbstractActionType, AnyError> {
        let req = self.request.map {$0 as RequestHeadType} .getOrElse(request)
        let body = self.request.map {$0.body.map {$0 as ContentType}} .getOrElse(request.body)
        
        let route = app.nextRoute(routeId, request: request)
        return route.map { (r:(RouteType, UrlMatch))->Future<AbstractActionType, AnyError> in
            let req = req.withParams(r.1)
            let transaction = r.0.factory(req, out)
            for b in body {
                if !transaction.tryConsume(b) {
                    if let flushableBody = b as? FlushableContentType {
                        flushableBody.flushTo(transaction)
                    } else {
                        print("Can not chain this action")
                    }
                }
            }
            return transaction.action
        }.getOrElse {
            future(ImmediateExecutionContext) {
                throw ExpressError.PageNotFound(path: request.path)
            }
        }
    }
}

public extension Action {
    public class func ok(content:Content? = nil, headers:Dictionary<String, String> = Dictionary()) -> Action<C> {
        let response = Response<Content>(status: 200, content: content, headers: headers)
        return ResponseAction(response: response)
    }
    
    internal class func notFound(filename:String) -> Action<AnyContent> {
        let response = Response<AnyContent>(status: 404, content: AnyContent(str: "404 File Not Found\n\n" + filename), headers: Dictionary())
        return ResponseAction(response: response)
    }
    
    internal class func internalServerError(description:String) -> Action<AnyContent> {
        let response = Response<AnyContent>(status: 500, content: AnyContent(str: "500 Internal Server Error\n\n" + description), headers: Dictionary())
        return ResponseAction(response: response)
    }
    
    internal class func nilRequest() -> Request<AnyContent>? {
        return nil
    }
    
    public class func chain<ReqC : ConstructableContentType>(request:Request<ReqC>? = nil) -> Action<C> {
        return ChainAction(request: request)
    }
    
    public class func chain() -> Action<C> {
        return chain(nilRequest())
    }
    
    public class func render(view:String, context:AnyObject? = nil) -> Action<C> {
        return RenderAction(view: view, context: context)
    }
}