//
//  main.swift
//  SwiftExpress
//
//  Created by Daniel Leping on 12/16/15.
//  Copyright © 2015-2016 Daniel Leping (dileping)
//

import Foundation
import Express
import BrightFutures

let app = express()

//always enable for production
//app.views.cache = true

app.views.register(JsonView())
app.views.register(MustacheViewEngine())
app.views.register(StencilViewEngine())

enum TestError {
    case Test
    case Test2
    
    func items() -> Dictionary<String, String> {
        switch self {
            case .Test: return ["blood": "red"]
            case .Test2: return ["sickness": "purple"]
        }
    }
}

extension TestError : ErrorType {
}

func test() throws -> Action<AnyContent> {
    throw TestError.Test2
}

app.errorHandler.register { e in
    guard let e = e as? TestError else {
        return nil
    }
    
    let items = e.items()
    
    let viewItems = items.map { (k, v) in
        ["name": k, "color": v]
    }
    
    let context:[String: Any] = ["test": "error", "items": viewItems]
    
    return Action<AnyContent>.render("test", context: context)
}

/// StaticAction is just a predefined configurable handler for serving static files.
/// It's important to pass exactly the same param name to it from the url pattern.
app.get("/:file+", action: StaticAction(path: "public", param:"file"))

app.get("/hello") { request in
    return Action.ok(AnyContent(str: "<h1>Hello Express!!!</h1>", contentType: "text/html"))
}

//user as an url param
app.get("/hello/:user.html") { request in
    //get user
    let user = request.params["user"]
    //if there is a user - create our context. If there is no user, context will remain nil
    let context = user.map {["user": $0]}
    //render our template named "hello"
    return Action.render("hello", context: context)
}

//user as an url param
app.get("/hello2/:user.html") { request in
    //get user
    let user = request.params["user"]
    //if there is a user - create our context. If there is no user, context will remain nil
    let context = user.map {["user": $0]}
    //render our template named "hello"
    return Action.render("hello2", context: context)
}

app.post("/api/user") { request in
    //check if JSON has arrived
    guard let json = request.body?.asJSON() else {
        return Action.ok("Invalid request")
    }
    //check if JSON object has username field
    guard let username = json["username"].string else {
        return Action.ok("Invalid request")
    }
    //compose the response as a simple dictionary
    let response =
        ["status": "ok",
        "description": "User with username '" + username + "' created succesfully"]
    
    //render disctionary as json (remember the one we've registered above?)
    return Action.render(JsonView.name, context: response)
}

app.get("/myecho") { request in
    return Action.ok(request.query["message"]?.first)
}

//:param - this is how you define a part of URL you want to receive through request object
app.get("/myecho/:param") { request in
    //here you get the param from request: request.params["param"]
    return Action.ok(request.params["param"])
}

func factorial(n: Int) -> Int {
    return n == 0 ? 1 : n * factorial(n - 1)
}

func calcFactorial(num:Int) -> Future<Int, AnyError> {
    return future {
        return factorial(num)
    }
}

// (request -> Future<Action<AnyContent>, AnyError> in) - this is required to tell swift you want to return a Future
// hopefully inference in swift will get better eventually and just "request in" will be enough
app.get("/factorial/:num(\\d+)") { request -> Future<Action<AnyContent>, AnyError> in
    // get the number from the url
    let num = request.params["num"].flatMap{Int($0)}.getOrElse(0)
    
    // get the factorial Future. Returns immediately - non-blocking
    let factorial = calcFactorial(num)
    
    //map the result of future to Express Action
    let future = factorial.map { fac in
        Action.ok(String(fac))
    }
    
    //return the future
    return future
}

app.get("/test") { req in
    return future {
        return try test()
    }
}

func testItems(request:Request<AnyContent>) throws -> [String: Any] {
    let newItems = request.query.map { (k, v) in
        (k, v.first!)
    }
    let items = ["sky": "blue", "fire": "red", "grass": "green"] ++ newItems
    
    let viewItems = items.map { (k, v) in
        ["name": k, "color": v]
    }
    
    if ((request.query["throw"]?.first) != nil) {
        throw TestError.Test
    }
    
    return ["test": "ok", "items": viewItems]
}

app.get("/test.html") { request in
    let items = try testItems(request)
    return Action.render("test", context: items)
}

app.get("/test2.html") { request in
    return Action.render("test2", context: try testItems(request))
}

app.get("/echo") { request in
    return Action.chain()
}

app.get("/myecho") { request in
    return Action.ok(AnyContent(str: request.query["message"]?.first))
}

app.get("/hello") { request in
    return Action.ok(AnyContent(str: "<h1>Hello Express!!!</h1>", contentType: "text/html"))
}

app.get("/") { request in
    for me in request.body?.asJSON().map({$0["test"]}) {
        print(me)
    }
    return Action.ok(AnyContent(str:"{\"response\": \"hey hey\"}", contentType: "application/json"))
}

func echoData(request:Request<AnyContent>) -> Dictionary<String, String> {
    let call = request.body?.asJSON().map({$0["say"]})?.string
    let response = call.getOrElse("I don't hear you!")
    return ["said": response]
}

func echo(request:Request<AnyContent>) -> Action<AnyContent> {
    let data = echoData(request)
    let tuple = data.first!
    let str = "{\"" + tuple.0 + "\": \"" + tuple.1 + "\"}"
    
    return Action<AnyContent>.ok(AnyContent(str:str, contentType: "application/json"))
}

func echoRender(request:Request<AnyContent>) -> Action<AnyContent> {
    var data = echoData(request)
    data["hey"] = "Hello from render"
    return Action.render(JsonView.name, context: data)
}

app.post("/echo/inline") { request in
    let call = request.body?.asJSON().map({$0["say"]})?.string
    let response = call.getOrElse("I don't hear you!")
    
    return Action.ok(AnyContent(str:"{\"said\": \"" + response + "\"}", contentType: "application/json"))
}

app.get("/echo") { request in
    return echo(request)
}

app.get("/echo/render", handler: echoRender)
app.post("/echo/render", handler: echoRender)

app.post("/echo") { request in
    return echo(request)
}

app.post("/echo2") { request in
    return Action.ok(AnyContent(str: request.body?.asText().map {"Text echo: " + $0},
        contentType: request.contentType))
}

app.post("/echo3") { request in
    return Action.ok(AnyContent(data: request.body?.asRaw(),
        contentType: request.contentType))
}

app.all("/async/echo") { request in
    return future {
        return echo(request)
    }
}

app.get("/test/redirect") { request in
    return future {
        let to = request.query["to"].flatMap{$0.first}.getOrElse("../test.html")
        return Action.redirect(to)
    }
}

app.post("/merged/query") { request in
    Action.render(JsonView.name, context: request.mergedQuery())
}

app.listen(9999).onSuccess {
    print("Successfully launched server")
}

app.run()

//TODO: proper error handling for sync requests