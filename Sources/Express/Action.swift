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
import Future
import ExecutionContext

public protocol AbstractActionType {
}

public protocol ActionType : AbstractActionType {
    associatedtype Content
}

public protocol FlushableAction : AbstractActionType, FlushableType {
}

public protocol IntermediateActionType : AbstractActionType {
    func nextAction<RequestContent : ConstructableContentType>(request:Request<RequestContent>) -> Future<(AbstractActionType, Request<RequestContent>?)>
}

public protocol SelfSufficientActionType : AbstractActionType {
    func handle<RequestContent : ConstructableContentType>(app:Express, routeId:String, request:Request<RequestContent>, out:DataConsumerType) -> Future<Void>
}

public class Action<C : FlushableContentType> : ActionType, AbstractActionType {
    public typealias Content = C
}

class ResponseAction<C : FlushableContentType> : Action<C>, FlushableAction {
    let response:Response<C>
    
    init(response:Response<C>) {
        self.response = response
    }
    
    func flushTo(out: DataConsumerType) -> Future<Void> {
        return response.flushTo(out: out)
    }
}

extension ResponseAction where C : FlushableContent {
    convenience init(response:ResponseType) {
        let content = response.content.map { content in
            C(content: content)
        }
        let mappedResponse = Response<C>(status: response.status, content: content, headers: response.headers)
        self.init(response: mappedResponse)
    }
}

class RenderAction<C : FlushableContentType, Context> : Action<C>, IntermediateActionType {
    let view:String
    let context:Context?
    let status:StatusCode
    let headers:Dictionary<String, String>
    
    init(view:String, context:Context?, status:StatusCode = .Ok, headers:Dictionary<String, String> = Dictionary()) {
        self.view = view
        self.context = context
        self.status = status
        self.headers = headers
    }
    
    private func response<RC:FlushableContentType>(status:StatusCode, content:RC?, headers:Dictionary<String, String>) -> Response<RC> {
        return Response(status: status, content: content, headers: headers)
    }
    
    func nextAction<RequestContent : ConstructableContentType>(request:Request<RequestContent>) -> Future<(AbstractActionType, Request<RequestContent>?)> {
        return request.app.views.render(view: view, context: context).map { content in
            let response = Response(status: self.status, content: content, headers: self.headers)
            return (ResponseAction(response: response), nil)
        }
    }
}

class ChainAction<C : FlushableContentType, ReqC: ConstructableContentType> : Action<C>, SelfSufficientActionType {
    let request:Request<ReqC>?
    
    init(request:Request<ReqC>? = nil) {
        self.request = request
    }
    
    func handle<RequestContent : ConstructableContentType>(app:Express, routeId:String, request:Request<RequestContent>, out:DataConsumerType) -> Future<Void> {
        let req = self.request.map {$0 as RequestHeadType} ?? request
        let body = self.request.flatMap {$0.body.flatMap {$0 as ContentType}} ?? request.body
        
        let route = app.nextRoute(routeId: routeId, request: request)
        return route.map { (r:(RouteType, [String: String]))->Future<Void> in
            let req = req.withParams(params: r.1, app: app)
            let transaction = r.0.factory(req, out)
            if let body = body {
                if !transaction.tryConsume(content: body) {
                    if let flushableBody = body as? FlushableContentType {
                        flushableBody.flushTo(out: transaction)
                    } else {
                        print("Can not chain this action")
                    }
                }
            }
            transaction.selfProcess()
            return Future<Void>(value: ())
        }.getOrElse {
            future(context: immediate) { ()->Void in
                throw ExpressError.PageNotFound(path: request.path)
            }
        }
    }
}

public extension Action {
    public class func ok(_ content:Content? = nil, headers:Dictionary<String, String> = Dictionary()) -> Action<C> {
        let response = Response<Content>(status: 200, content: content, headers: headers)
        return ResponseAction(response: response)
    }
    
    internal class func notFound(filename:String) -> Action<AnyContent> {
        let response = Response<AnyContent>(status: 404, content: AnyContent(str: "404 File Not Found\n\n" + filename), headers: Dictionary())
        return ResponseAction(response: response)
    }
    
    internal class func routeNotFound(path:String) -> Action<AnyContent> {
        let response = Response<AnyContent>(status: 404, content: AnyContent(str: "404 Route Not Found\n\n\tpath: " + path), headers: Dictionary())
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
        return chain(request: nilRequest())
    }
    
    public class func render<Context>(view:String, context:Context? = nil, status:StatusCode = .Ok, headers:Dictionary<String, String> = Dictionary()) -> Action<C> {
        return RenderAction(view: view, context: context, status: status, headers: headers)
    }
    
    public class func response(response:Response<C>) -> Action<C> {
        return ResponseAction(response: response)
    }
    
    public class func response(status:UInt16, content:C? = nil, headers:Dictionary<String, String> = Dictionary()) -> Action<C> {
        return response(response: Response(status: status, content: content, headers: headers))
    }
    
    public class func response(status:StatusCode, content:C? = nil, headers:Dictionary<String, String> = Dictionary()) -> Action<C> {
        return response(status:status.rawValue, content: content, headers: headers)
    }
    
    public class func status(status:UInt16) -> Action<C> {
        return response(status: status)
    }
    
    public class func status(status:StatusCode) -> Action<C> {
        return self.status(status: status.rawValue)
    }
    
    public class func redirect(url:String, status:RedirectStatusCode) -> Action<C> {
        let headers = ["Location": url]
        return response(status: status.rawValue, headers: headers)
    }
    
    public class func redirect(url:String, permanent:Bool = false) -> Action<C> {
        let code:RedirectStatusCode = permanent ? .MovedPermanently : .TemporaryRedirect
        return redirect(url: url, status: code)
    }
    
    public class func found(url:String) -> Action<C> {
        return redirect(url: url, status: .Found)
    }
    
    public class func movedPermanently(url:String) -> Action<C> {
        return redirect(url: url, status: .MovedPermanently)
    }
    
    public class func seeOther(url:String) -> Action<C> {
        return redirect(url: url, status: .SeeOther)
    }
    
    public class func temporaryRedirect(url:String) -> Action<C> {
        return redirect(url: url, status: .TemporaryRedirect)
    }
}

public extension Action where C : AnyContent {
    public class func ok(_ str:String?) -> Action<AnyContent> {
        return Action<AnyContent>.ok(AnyContent(str: str))
    }
}
