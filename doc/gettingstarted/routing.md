# Basic Routing

[Express](http://swiftexpress.io) routing definitions have the following pattern:

```swift
app.METHOD(PATH, HANDLER)
```

`METHOD` can be one of the `get`, `post`, `put`, `delete`, `patch` or `all`.

##### Examples:

Respond with `Hello World!` on the homepage:

```swift
app.get("/") { request in
    return Action.ok("Hello World!")
}
```

Respond to `POST` request on the root route `/`, the application’s home page:

```swift
app.post("/") { request in
    return Action.ok("Got a POST request")
}
```

Respond to a `PUT` request to the `/user` route:

```swift
app.put("/user") { request in
    return Action.ok("Got a PUT request at /user")
}
```

Respond to a `DELETE` request to the `/user` route:

```swift
app.delete("/user") { request in
    return Action.ok("Got a DELETE request at /user")
}
```

Respond to all methods requests on the `/user` route:

```swift
app.all("/user") { request in
    return Action.ok("Got a " + request.method + " request at /user")
}
```


# Next tutorial: [Static files](./static.md)