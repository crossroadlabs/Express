//
//  main.swift
//  SwiftExpress
//
//  Created by Daniel Leping on 12/16/15.
//  Copyright © 2015-2016 Daniel Leping (dileping)
//

import Foundation
import Express
import Future

let app = express()

//always enable for production
//app.views.cache = true

app.views.register(JsonView())
app.views.register(MustacheViewEngine())
app.views.register(StencilViewEngine())

app.get(path: "/echo") { request in
    .ok(request.query["call"]?.first)
}

enum NastyError : Error {
    case recoverable
    case fatal(reason:String)
}

app.get(path: "/error/recovered") { request in
    .render(view: "error-recovered", context: [String:Any]())
}

app.get(path: "/error/:fatal?") { (request:Request<AnyContent>) throws -> Action<AnyContent>  in
    guard let fatal = request.params["fatal"] else {
        throw NastyError.recoverable
    }
    
    throw NastyError.fatal(reason: fatal)
}

app.errorHandler.register { (e:NastyError) in
    switch e {
    case .recoverable:
        return .redirect(url: "/error/recovered")
    case .fatal(let reason):
        let content = AnyContent(str: "Unrecoverable nasty error happened. Reason: " + reason)
        return .response(status: .InternalServerError, content: content)
    }
}

/// Custom page not found error handler
app.errorHandler.register { (e:ExpressError) in
    switch e {
    case .PageNotFound(let path):
        return .render(view: "404", context: ["path": path], status: .NotFound)
    case  .RouteNotFound(let path):
        return .render(view: "404", context: ["path": path], status: .NotFound)
    default:
        return nil
    }
}

/// StaticAction is just a predefined configurable handler for serving static files.
/// It's important to pass exactly the same param name to it from the url pattern.
app.get(path: "/assets/:file+", action: StaticAction(path: "public", param:"file"))

app.get(path: "/hello") { request in
    .ok(AnyContent(str: "<h1><center>Hello Express!!!</center></h1>", contentType: "text/html"))
}

//user as an url param
app.get(path: "/hello/:user.html") { (request) -> Action<AnyContent>  in
    //get user
    let user = request.params["user"]
    //if there is a user - create our context. If there is no user, context will remain nil
    let context = user.map {["user": $0]}
    //render our template named "hello"
    return .render(view: "hello", context: context)
}

app.post(path: "/api/user") { (request) -> Action<AnyContent> in
    //check if JSON has arrived
    guard let json = request.body?.asJSON() else {
        return .ok("Invalid request")
    }
    //check if JSON object has username field
    guard let username = json["username"].string else {
        return .ok("Invalid request")
    }
    //compose the response as a simple dictionary
    let response =
        ["status": "ok",
        "description": "User with username '" + username + "' created succesfully"]
    
    //render disctionary as json (remember the one we've registered above?)
    return .render(view: JsonView.name, context: response)
}

//:param - this is how you define a part of URL you want to receive through request object
app.get(path: "/echo/:param") { request in
    //here you get the param from request: request.params["param"]
    .ok(request.params["param"])
}

func factorial(n: Double) -> Double {
    return n == 0 ? 1 : n * factorial(n: n - 1)
}

func calcFactorial(num:Double) -> Future<Double> {
    return future {
        factorial(n: num)
    }
}

// (request -> Future<Action<AnyContent>> in) - this is required to tell swift you want to return a Future
// hopefully inference in swift will get better eventually and just "request in" will be enough
app.get(path: "/factorial/:num(\\d+)") { request -> Future<Action<AnyContent>> in
    // get the number from the url
    let num = request.params["num"].flatMap{Double($0)}.getOrElse(el: 0)
    
    // get the factorial Future. Returns immediately - non-blocking
    let factorial = calcFactorial(num: num)
    
    //map the result of future to Express Action
    return factorial.map(String.init).map {.ok($0)}
}

func testItems(request:Request<AnyContent>) throws -> [String: Any] {
    let newItems = request.query.map { (k, v) in
        (k, v.first!)
    }
    let items = ["sky": "blue", "fire": "red", "grass": "green"] ++ newItems
    
    let viewItems = items.map { (k, v) in
        ["name": k, "color": v]
    }
    
    if let reason = request.query["throw"]?.first {
        throw NastyError.fatal(reason: reason)
    }
    
    return ["test": "ok", "items": viewItems]
}

app.get(path: "/render.html") { request in
    let items = try testItems(request: request)
    return .render(view: "test", context: items)
}

//TODO: make a list of pages
app.get(path: "/") { request -> Action<AnyContent> in
    let examples:[Any] = [
        ["title": "Hello Express", "link": "/hello", "id":"hello", "code": "code/hello.stencil"],
        ["title": "Echo", "link": "/echo?call=hello", "id":"echo", "code": "code/echo.stencil"],
        ["title": "Echo with param", "link": "/echo/hello", "id":"echo-param", "code": "code/echo-param.stencil"],
        ["title": "Error recoverable (will redirect to recover page)", "link": "/error", "id":"error", "code": "code/error.stencil"],
        ["title": "Error fatal", "link": "/error/thebigbanghappened", "id":"error-fatal", "code": "code/error.stencil"],
        ["title": "Custom 404", "link": "/thisfiledoesnotexist", "id":"404", "code": "code/404.stencil"],
        ["title": "Hello [username]. You can put your name instead", "link": "/hello/username.html", "id":"hello-username", "code": "code/hello-user.stencil"],
        ///api/user - implement JSON post form
        ["title": "Asynchronous factorial", "link": "/factorial/100", "id":"factorial", "code": "code/factorial.stencil"],
        ["title": "Render", "link": "/render.html?sun=yellow&clouds=lightgray", "id":"render", "code": "code/render.stencil"],
        ["title": "Redirect", "link": "/test/redirect", "id":"redirect", "code": "code/redirect.stencil"],
        ["title": "Merged query (form url encoded and query string)", "link": "/merged/query?some=param&another=param2", "id":"query", "code": "code/query.stencil"],
    ]
    
    let context:[String: Any] = ["examples": examples]
    
    return .render(view: "index", context: context)
}

app.get(path: "/test/redirect") { request in
    future {
        let to = request.query["to"].flatMap{$0.first}.getOrElse(el: "../render.html")
        return .redirect(url: to)
    }
}

app.all(path: "/merged/query") { request in
    .render(view: JsonView.name, context: request.mergedQuery())
}

app.get(path: "/mustache/:hello") { request in
    .render(view: "mustache", context: ["hello": request.params["hello"]])
}

app.listen(port: 9999).onSuccess { server in
    print("Express was successfully launched on port", server.port)
}

app.run()
