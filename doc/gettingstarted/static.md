# Static files

Static files are very easy to be served with [Express](http://swiftexpress.io):

```swift
app.get("/:file+", action: StaticAction(path: "public", param:"file"))
```

The code above tells [Express](http://swiftexpress.io/) to serve all static files from the `public` folder recursively (i.e. it will serve both `public/article.html` as well as `public/articles/awesome.html`). If you want to serve just the first level in folder, use:

```swift
app.get("/:file", action: StaticAction(path: "public", param:"file"))
```

The difference is just in the pattern: `/:file` versus `/:file+`. For more information see our [Advanced Routing](#) section.

# Next tutorial: [Basic error handling](./errorhandling.md)