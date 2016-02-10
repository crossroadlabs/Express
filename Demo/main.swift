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
    
    return Action<AnyContent>.render("test", context: ["test": "error", "items": viewItems])
}

app.get("/:file+", action: StaticAction(path: "public", param:"file"))

app.get("/test") { req in
    return future {
        return try test()
    }
}

app.get("/test.html") { (request:Request<AnyContent>)->Action<AnyContent> in
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
    
    return Action<AnyContent>.render("test", context: ["test": "ok", "items": viewItems])
}

app.get("/echo") { request in
    return Action<AnyContent>.chain()
}

app.get("/myecho") { request in
    return Action<AnyContent>.ok(AnyContent(str: request.query["message"]?.first))
}

app.get("/hello") { request in
    return Action<AnyContent>.ok(AnyContent(str: "<h1>Hello Express!!!</h1>", contentType: "text/html"))
}

app.get("/") { (request:Request<AnyContent>)->Action<AnyContent> in
    for me in request.body?.asJSON().map({$0["test"]}) {
        print(me)
    }
    return Action<AnyContent>.ok(AnyContent(str:"{\"response\": \"hey hey\"}", contentType: "application/json"))
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
    return Action.render("json", context: data)
}

app.post("/echo/inline") { (request:Request<AnyContent>)->Action<AnyContent> in
    let call = request.body?.asJSON().map({$0["say"]})?.string
    let response = call.getOrElse("I don't hear you!")
    
    return Action<AnyContent>.ok(AnyContent(str:"{\"said\": \"" + response + "\"}", contentType: "application/json"))
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

app.handle(HttpMethod.Any.rawValue, path: "/async/echo") { request in
    return future {
        return echo(request)
    }
}

app.listen(9999).onSuccess {
    print("Successfully launched server")
}

app.run()

//TODO: proper error handling for sync requests