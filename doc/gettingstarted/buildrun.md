# Building and running your [Express](http://swiftexpress.io/) app

This section is dedicated to different types and flavors of building and running [Express](http://swiftexpress.io/) apps. Differences between Linux and OS X systems are outlined explicitly.

## Building with [Express Command Line](https://github.com/crossroadlabs/ExpressCommandLine)

_At the moment of writing [Express Command Line](https://github.com/crossroadlabs/ExpressCommandLine) tools are available for OS X only, but soon to be ported to Linux as well. Stay tuned._

[Express Command Line](https://github.com/crossroadlabs/ExpressCommandLine) is the easiest way to work with [Express](http://swiftexpress.io/) apps. The building and running is as straightforward as:

```sh
swift-express build
swift-express run
```

For the full set of available parameters, please, refer to the main [documentation page](https://github.com/crossroadlabs/ExpressCommandLine).

## Building manually with [Swift Package Manager](https://github.com/apple/swift-package-manager)

[Swift Package Manager](https://github.com/apple/swift-package-manager) is the default way of building Swift apps. Most probably soon to be supported in xCode out of the box as well. If you don't want to use [Express Command Line](https://github.com/crossroadlabs/ExpressCommandLine) for some reason, here is how to build an express app manually.

### Development build

In development, it's generally not a good idea to build the app with [Dispatch](https://swift.org/core-libraries/#libdispatch) support on Linux as it becomes non-debuggable with lldb. To build an [Express](http://swiftexpress.io/) app without [Dispatch](https://swift.org/core-libraries/#libdispatch) run the following in terminal:

```sh
swift build --fetch
#swift build does not work with tests properly yet
rm -rf Packages/*/Tests
swift build
```

Now you can run your app with:

```sh
# note, that if you use port 80 you might need to do it with sudo
./.build/debug/YOUR_APP_NAME
```

### Production build

[Express](http://swiftexpress.io/) apps show a level of magnitude better performance when built with dispatch support. If you are using Linux, before continuing make sure you followed [Dispatch installation section](./installing.md#installing-dispatch-on-linux).

Here is how to build your app for production:

```sh
swift build --fetch
#swift build does not work with tests properly yet
rm -rf Packages/*/Tests
swift build -c release -Xcc -fblocks -Xswiftc -Ddispatch
```

Now you can run your app in production with:

```sh
# note, that if you use port 80 you might need to do it with sudo
./.build/release/YOUR_APP_NAME
```

# Next tutorial: [Basic Routing](./routing.md)