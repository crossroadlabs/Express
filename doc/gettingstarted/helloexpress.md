# Hello Express

This is a very basic application. Much simpler than one created with [Express Command Line](./commandline.md). Still it's good to understand the basic concepts by creating an app by hands. Keep in mind that you have to follow [Installation instructions](./installing.md) first. If you are doing it on a Mac, please, install [Swift 2.2 latest development](https://swift.org/download/#latest-development-snapshots) snapshot in addition.

##### If you don't want to create an app manually, just skip this tutorial and use [Express Command Line](./commandline.md) tool instead.

## Create a folder

Simple as that. We need a separate folder for the [Hello Express](#) app. Just run:

```sh
mkdir HelloExpress
cd HelloExpress
```

## Package.swift

[Package.swift](https://github.com/apple/swift-package-manager/blob/master/Documentation/Package.swift.md) is your project descriptor. Contains the name of the app and dependencies. Check [reference](https://github.com/apple/swift-package-manager/blob/master/Documentation/Package.swift.md) for more info.

Create one right in the current dirctory and put the following text inside (we have just one dependency to [Express](http://www.swiftexpress.io/)):

```swift
import PackageDescription

let package = Package(
    name: "HelloExpress",
    dependencies: [
        .Package(url: "https://github.com/crossroadlabs/Express.git", majorVersion: 0, minor: 3),
    ]
)
```

## The App

Create a folder `app` in current directory and put there a file named `main.swift`. The contents of the file should look like:

```swift
import Express

let app = express()

app.get("/") { request in
    return Action.ok("Hello Express!")
}

app.listen(9999).onSuccess { server in
    print("Express was successfully launched on port", server.port)
}

app.run()
```

This means that all the requests coming to the root will be responded with _Hello Express!_ string. All other requests will get `404`.

## Build tool

Swift on Linux and [Package Manager](https://github.com/apple/swift-package-manager) are early tools and are a bit complicated to use. We created a simple tool to build Swift on Linux. Get it using following commands:

```sh
wget https://raw.githubusercontent.com/crossroadlabs/utils/master/build
chmod a+x build
```

## Build

Just type in terminal:

```sh
./build
```

## Run

Run our new app with:

```sh
./.build/debug/app
```

In the console you should see something like this:

```
Express was successfully launched on port 9999
```

## Test

Enter the following url in the browser: [http://localhost:9999/](http://localhost:9999/). You should now see text:

```
http://localhost:9999/
```

# Next tutorial: [Express Command Line](./commandline.md)