# Swift Express

[![GitHub license](https://img.shields.io/badge/license-LGPL v3-lightgrey.svg)](https://raw.githubusercontent.com/crossroadlabs/Express/master/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Platform OS X | Linux](https://img.shields.io/badge/platform-OS%20X%20%7C%20Linux-orange.svg)

### Express is a simple, yet unopinionated web application server written in Swift

## Getting started

First make sure, please, you have followed the [installation](#installation) section steps.

##### Create a project:

```sh
swift-express init HelloExpress
cd HelloExpress
open HelloExpress.xcodeproj
```

##### Create new API:

```swift
app.get("/myecho") { request in
    return Action.ok(request.query["message"]?.first)
}
```

##### Run from xCode or command line with:

```sh
swift-express run
```

Test it in the browser: [http://localhost:9999/myecho?message=Hello](http://localhost:9999/myecho?message=Hello)

##### A complete Swift Express command line documentation can be found here: [https://github.com/crossroadlabs/ExpressCommandLine](https://github.com/crossroadlabs/ExpressCommandLine)


## Installation

[//]: # (Icons are here: https://www.iconfinder.com/icons/395228/linux_tox_icon#size=16)

### [OS X ![OS X](https://cdn1.iconfinder.com/data/icons/system-shade-circles/512/mac_os_X-16.png)](http://www.apple.com/osx/)

##### First install the following components (if you have not yet):

* [XCode](https://developer.apple.com/xcode/download/) 7.2 or higher
* [Homebrew](http://brew.sh/) the latest available version
* Command Line tools: run ```xcode-select --install``` in terminal

##### Run the following in terminal:

```sh
brew tap crossroadlabs/tap
brew install swift-express
```

#### [Linux ![Linux](https://cdn1.iconfinder.com/data/icons/system-shade-circles/512/linux_tox-16.png)](http://www.linux.org/)

##### Stay tuned! We are working hard on this.

## Examples

Create a project as it is described in the [getting started](#getting-started) section. Now you can start playing with examples.

All the examples can be found in `Demo` project inside the main repo.

### Hello Express:

```swift
app.get("/hello") { request in
    return Action.ok(AnyContent(str: "<h1>Hello Express!!!</h1>", contentType: "text/html"))
}
```

Launch the app and follow the link: [http://localhost:9999/hello?message=Hello](http://localhost:9999/hello?message=Hello)

### Synchronous vs Asynchronous

Express can handle it both ways. All your syncronous code will be executed in a separate queue in a traditional way, so if you are a fan of this approach - it will work (like in "Hello Express" example above).

Still if you want to benefit from asynchronicity, we provide a very powerful API set that accepts futures as result of your handler.

Let's assume you have following function somewhere:

```swift
func calcFactorial(num:Int) -> Future<Int, AnyError>
```

it's a purely asyncronous function that returns future. It would be really nice if it could be handled asynchronously as well in a nice functional way. Here is an example of how it could be done.


```swift
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
```

### Url params

Let's get our echo example from [Getting Started](#getting-started) a bit further. Our routing engine, which is largely based on NodeJS analog [path-to-regex](https://github.com/pillarjs/path-to-regexp). You can read the complete documentation on how to use path patterns [here](https://github.com/pillarjs/path-to-regexp). Now an example with URL param:

```swift
//:param - this is how you define a part of URL you want to receive through request object
app.get("/myecho/:param") { request in
    //here you get the param from request: request.params["param"]
    return Action.ok(request.params["param"])
}
```

### Serving static files

```swift
app.get("/:file+", action: StaticAction(path: "public", param:"file"))
```

The code above tells Express to serve all static files from the public folder recursively. If you want to serve just the first level in folder, use:

```swift
app.get("/:file", action: StaticAction(path: "public", param:"file"))
```

The difference is just in the pattern: `/:file` versus `/:file+`. For more information see our routing section.

### Serving JSON requests

Let's say we want to build a simple API for users registration. We want our API consumers to `POST` to `/api/user` a JSON object and get a `JSON` response back.

```swift
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
    
    //render disctionary as json
    return Action.render("json", context: response)
}
```

Lines above will do the job. Post this `JSON`:

```json
{
    "username": "swiftexpress"
}
```

to our api URL: `http://localhost:9999/api/user` (don't forget `application/json` content type header) and you will get this response:

```json
{
  "status": "ok",
  "description": "User with username 'swiftexpress' created succesfully"
}
```

### Using template engine

First of all you need to switch the template engine on:

```swift
//we recommend mustache template engine
app.views.register(MustacheViewEngine())
```

No create a file called `hello.mustache` in the `views` directory:

```mustache
<html>
<body>
<h1>Hello: {{user}}</h1>
</body>
</html>
```

Add a new request handler:
```swift
//user as an url param
app.get("/hello/:user.html") { request in
    //get user
    let user = request.params["user"]
    //if there is a user - create our context. If there is no user, context will remain nil
    let context = user.map {["user": $0]}
    //render our template named "hello"
    return Action.render("hello", context: context)
}
```

Now follow the link to see the result: [http://localhost:9999/hello/express.html](http://localhost:9999/hello/express.html)

## Ideology behind

### Taking the best of Swift

[Swift](https://swift.org/) essentially is a new generation programming language combining simplicity and all the modern stuff like functional programming.

We were inspired (and thus influenced) mainly by two modern web frameworks: [Express.js](http://expressjs.com/) and [Play](https://www.playframework.com/). So, we are trying to combine the best of both worlds taking simplicity from [Express.js](http://expressjs.com/) and modern robust approach of [Play](https://www.playframework.com/)

Let us know if we are on the right path! Influence the project, create feature requests, API change requests and so on. While we are in our early stages, it's easy to change. We are open to suggestions!

## Features

* 100% asynchronous (Future-based API)
* Flexible and extensible
* Full [MVC](https://ru.wikipedia.org/wiki/Model-View-Controller) support
* Swift 2.1 compatible
* Simple routing mechanism
* Request handlers chaining
* Easy error handling
* [Mustache](https://mustache.github.io) templates
* Built-in [JSON](http://www.json.org) support
* Easy creation of [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer) APIs
* Built-in static files serving
* Multiple contents types built-in support

### And heah, the most important feature: [Highly passionate development team](http://www.crossroadlabs.xyz/)

## Roadmap

* v0.3: Linux support
* v0.4: proper streaming APIs
* v0.5: more content types available out of the box
* v0.6: Web Sockets
* v1.0: hit the production!

## Changelog

* v0.2:
	* Much better routing APIs
	* Advanced routing path patterns
	* Possibility to use Regex for routing

* v0.1: Initial Public Release
	* basic routing
	* views and view engines (supports [Mustache](https://mustache.github.io/))
	* JSON rendering as a view
	* query parsing
	* static files serving

## Contributing

To get started, <a href="https://www.clahub.com/agreements/crossroadlabs/Express">sign the Contributor License Agreement</a>.

## [![Crossroad Labs](http://i.imgur.com/iRlxgOL.png?1) by Crossroad Labs](http://www.crossroadlabs.xyz/)