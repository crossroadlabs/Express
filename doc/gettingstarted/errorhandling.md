# Basic error handling

If you want to generate an error in [Express](http://swiftexpress.io/) you need to throw an exception.

Let's say you have a `NastyError` defined:

```swift
enum NastyError : ErrorType {
    case Recoverable
    case Fatal(reason:String)
}
```

Here is an example on how to throw it:

```swift
app.get("/error/:fatal?") { request in
    guard let fatal = request.params["fatal"] else {
        throw NastyError.Recoverable
    }
    
    throw NastyError.Fatal(reason: fatal)
}
```

Now how to handle it. In [Express](http://swiftexpress.io/) you can define error handlers of two types. General and specific. Specific are the ones with the specified `Error` type. In our case it's `NastyError`. Here is an example:

```swift
app.errorHandler.register { (e:NastyError) in
    switch e {
    case .Recoverable:
        return Action<AnyContent>.redirect("/")
    case .Fatal(let reason):
        let content = AnyContent(str: "Unrecoverable nasty error happened. Reason: " + reason)
        return Action<AnyContent>.response(.InternalServerError, content: content)
    }
}
```

General error handlers are the same except you omit the error type. Something like this:

```swift
app.errorHandler.register { e in
    return nil
}
```

If your handler can handle the error, you return an `Action`. Otherwise you return `nil`. Here is an example of selective error handling:

```swift
/// Custom page not found error handler
app.errorHandler.register { (e:ExpressError) in
    switch e {
    case .PageNotFound(let path):
        return Action<AnyContent>.render("404", context: ["path": path], status: .NotFound)
    default:
        return nil
    }
}
```


# Next tutorial: [Advanced something](#)