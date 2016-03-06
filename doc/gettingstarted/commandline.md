# Express Command Line

<table bgcolor="#ff0000">
<tr><td>
<p align="right">
	<font color="cornflowerblue">
		Note: Express Command Line tool is not yet officially supported on Linux. This tutorial works on OS X only.
	</font>
</p>
</td></tr>
</table>

Using [Express](http://swiftexpress.io) is rather easy. To create a project you just need to type:

```sh
swift-express init YourProject
```

ant it will create you the whole directory structure along with xCode project.

No you need to fetch and build the dependencies:

```sh
cd YourProject
swift-express bootstrap
```

Build the project:

```sh
swift-express build
```

You can run your project by typing following test while in the project folder:

```sh
swift-express run
```

Full documentation of [Express Command Line](https://github.com/crossroadlabs/ExpressCommandLine) can be found here [crossroadlabs/ExpressCommandLine](https://github.com/crossroadlabs/ExpressCommandLine).

# Next tutorial: [Building and running](./buildrun.md)

