[//]: https://www.iconfinder.com/icons/383207/doc_tag_icon#size=64
<p align="left">
  <a href="http://swiftexpress.io/">
    <img alt="Swift Express" src ="./logo-full.png" />
  </a>
</p>

<h5>
<a href="./doc/index.md"><img src="https://cdn0.iconfinder.com/data/icons/glyphpack/82/tag-doc-64.png" height=16 /> Documentation</a>&nbsp;&nbsp;&nbsp;
<a href="http://demo.swiftexpress.io/"><img src="https://cdn0.iconfinder.com/data/icons/glyphpack/34/play-circle-32.png" height=16 /> Live linux server running Demo</a>&nbsp;&nbsp;&nbsp;
<a href="http://swiftexpress.io/" /><img src="https://cdn0.iconfinder.com/data/icons/glyphpack/147/globe-full-32.png" height=16/> Eating our own dog food</a>
</h5>

![🐧 linux: ready](https://img.shields.io/badge/%F0%9F%90%A7%20linux-ready-red.svg)
[![Build Status](https://travis-ci.org/crossroadlabs/Express.svg?branch=master)](https://travis-ci.org/crossroadlabs/Express)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Platform OS X | Linux](https://img.shields.io/badge/platform-OS%20X%20%7C%20Linux-orange.svg)
![Swift version](https://img.shields.io/badge/Swift-2.1 | 2.2-blue.svg)
[![GitHub license](https://img.shields.io/badge/license-LGPL v3-green.svg)](https://raw.githubusercontent.com/crossroadlabs/Express/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/crossroadlabs/Express.svg)](https://github.com/crossroadlabs/Express/releases)
<br />

Being [perfectionists](http://www.crossroadlabs.xyz), we took the best from what we think is the best: power of [Play Framework](https://www.playframework.com/) and simplicity of [Express.js](http://expressjs.com/)

Express is an asynchronous, simple, powerful, yet unopinionated web application server written in Swift.

<p>
  <a href="https://twitter.com/swift_express" target="_blank"><img align="left" vspace=5 src="https://cdn4.iconfinder.com/data/icons/social-messaging-ui-color-shapes-2-free/128/social-twitter-circle-128.png" height=25 alt="Twitter"/></a>
  <a href="https://www.facebook.com/swiftexpress.io" target="_blank"><img align="left" vspace=5 src="https://cdn4.iconfinder.com/data/icons/social-messaging-ui-color-shapes-2-free/128/social-facebook-circle-128.png" height=25 alt="Facebook"/></a>
  <a href="https://www.linkedin.com/company/swift-express" target="_blank"><img align="left" vspace=5 src="https://cdn4.iconfinder.com/data/icons/social-messaging-ui-color-shapes-2-free/128/social-linkedin-circle-128.png" height=25 alt="LinkedIn"/></a>
  <a href="http://swiftexpress.io" target="_blank"><img align="left" vspace=5 src="https://cdn3.iconfinder.com/data/icons/internet-and-web-4/78/internt_web_technology-01-128.png" height=25 alt="Web site"/></a>
  <a href="mailto:slack@swiftexpress.io?Subject=Add me to Slack" target="_blank"><img vspace=2 align="left" src="https://cdn0.iconfinder.com/data/icons/picons-social/57/109-slack-128.png" height=29 alt="Slack"/></a>
</p>
<br /><br />

## Getting started

First make sure, please, you have followed the [installation](#installation) section steps.

##### Create a project:

```sh
swift-express init HelloExpress
cd HelloExpress
swift-express bootstrap
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
swift-express build
swift-express run
```

Test it in the browser: [http://localhost:9999/myecho?message=Hello](http://localhost:9999/myecho?message=Hello)

##### A complete Swift Express command line documentation can be found here: [https://github.com/crossroadlabs/ExpressCommandLine](https://github.com/crossroadlabs/ExpressCommandLine)


## Installation

[//]: # (Icons are here: https://www.iconfinder.com/icons/395228/linux_tox_icon#size=16)

#### OS X

##### First install the following components (if you have not yet):

* [XCode](https://developer.apple.com/xcode/download/) 7.2 or higher
* [Homebrew](http://brew.sh/) the latest available version
* Command Line tools: run ```xcode-select --install``` in terminal

##### Run the following in terminal:

```sh
brew tap crossroadlabs/tap
brew install swift-express
```

#### Linux

##### For instructions on how to get [Express](http://swiftexpress.io/) installed on Linux, please, refer to the [installation section](./doc/gettingstarted/installing.md#linux-) in the [ducumentation](./doc/index.md).

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

If you don't know what this is you might want to better skip it for now to the next section: [URL params](#url-params). To get more information see [this](http://cs.brown.edu/courses/cs168/s12/handouts/async.pdf) first. We have our APIs based on [Future pattern](https://en.wikipedia.org/wiki/Futures_and_promises). Our implementation is based on [BrightFutures](https://github.com/Thomvis/BrightFutures), thanks @Thomvis!

Express can handle it both ways. All your syncronous code will be executed in a separate queue in a traditional way, so if you are a fan of this approach - it will work (like in "Hello Express" example above).

Still if you want to benefit from asynchronicity, we provide a very powerful API set that accepts futures as result of your handler.

Let's assume you have following function somewhere:

```swift
func calcFactorial(num:Double) -> Future<Double, AnyError>
```

it's a purely asyncronous function that returns future. It would be really nice if it could be handled asynchronously as well in a nice functional way. Here is an example of how it could be done.


```swift
// (request -> Future<Action<AnyContent>, AnyError> in) - this is required to tell swift you want to return a Future
// hopefully inference in swift will get better eventually and just "request in" will be enough
app.get("/factorial/:num(\\d+)") { request -> Future<Action<AnyContent>, AnyError> in
    // get the number from the url
    let num = request.params["num"].flatMap{Double($0)}.getOrElse(0)

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

### URL params

Let's get our echo example from [Getting Started](#getting-started) a bit further. Our routing engine, which is largely based on NodeJS analog [path-to-regex](https://github.com/pillarjs/path-to-regexp). You can read the complete documentation on how to use path patterns [here](https://github.com/pillarjs/path-to-regexp). Now an example with URL param:

```swift
//:param - this is how you define a part of URL you want to receive through request object
app.get("/echo/:param") { request in
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

First of all we need to register the JSON view in the system:

```swift
//now we can refer to this view by name
app.views.register(JsonView())
```

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

    //render disctionary as json (remember the one we've registered above?)
    return Action.render(JsonView.name, context: response)
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
app.views.register(StencilViewEngine())
```

Now create a file called `hello.stencil` in the `views` directory:

```stencil
<html>
<body>
<h1>Hello from Stencil: {{user}}</h1>
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


### If you want more, please, visit our [documentation](./doc/index.md) page

## Ideology behind

### Taking the best of Swift

[Swift](https://swift.org/) essentially is a new generation programming language combining simplicity and all the modern stuff like functional programming.

We were inspired (and thus influenced) mainly by two modern web frameworks: [Express.js](http://expressjs.com/) and [Play](https://www.playframework.com/). So, we are trying to combine the best of both worlds taking simplicity from [Express.js](http://expressjs.com/) and modern robust approach of [Play](https://www.playframework.com/)

Let us know if we are on the right path! Influence the project, create feature requests, API change requests and so on. While we are in our early stages, it's easy to change. We are open to suggestions!

## Features

* 🐧 Linux support with and without [Dispatch](https://swift.org/core-libraries/#libdispatch)
* 100% asynchronous (Future-based API)
* Flexible and extensible
* Full [MVC](https://ru.wikipedia.org/wiki/Model-View-Controller) support
* Swift 2.1 and 2.2 compatible
* [Simple routing mechanism](./doc/gettingstarted/routing.md)
* Request handlers chaining
* [Typesafe Error Handlers](./doc/gettingstarted/errorhandling.md)
* Templates: [Stencil](https://github.com/kylef/Stencil) and [Mustache](https://mustache.github.io)
* Built-in [JSON](http://www.json.org) support
* Easy creation of [RESTful](https://en.wikipedia.org/wiki/Representational_state_transfer) APIs
* Built-in [static files serving](./doc/gettingstarted/static.md)
* Multiple contents types built-in support

### And heah, the most important feature: [Highly passionate development team](http://www.crossroadlabs.xyz/)

## Roadmap

* v0.4: proper streaming APIs
* v0.5: more content types available out of the box
* v0.6: Web Sockets
* v0.7: hot code reload
* v1.0: hit the production!

## Changelog

* v0.3: linux support
	* Runs on linux with and without [Dispatch](https://swift.org/core-libraries/#libdispatch) support (see [installation section](./doc/gettingstarted/installing.md#linux-) and [building in production](./doc/gettingstarted/buildrun.md#production-build))
	* FormUrlEncoded ContentType support
	* Merged Query (params from both query string and form-url-encoded body merged together)
	* Utility methods (redirect, status, etc)
	* [Stencil](https://github.com/kylef/Stencil) Templete Engine Support
	* Replaced [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) with [TidyJSON](https://github.com/benloong/TidyJSON)
	* [Typesafe Error Handlers](./doc/gettingstarted/errorhandling.md)
	* Better Demo app
* v0.2.1: minor changes
	* Swift modules are installed via Carthage
	* Enabled binary builds on OS X
* v0.2: Solid OS X release
	* Much better routing APIs
	* Advanced routing path patterns
	* Possibility to use Regex for routing
	* Greately improved README
	* Some bugfixes
* v0.1: Initial Public Release
	* basic routing
	* views and view engines (supports [Mustache](https://mustache.github.io/))
	* JSON rendering as a view
	* query parsing
	* static files serving

## Contributing

To get started, <a href="https://www.clahub.com/agreements/crossroadlabs/Express">sign the Contributor License Agreement</a>.

## [![Crossroad Labs](http://i.imgur.com/iRlxgOL.png?1) by Crossroad Labs](http://www.crossroadlabs.xyz/)
