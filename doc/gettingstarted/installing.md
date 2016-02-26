#Installing 

## [OS X ![OS X](https://cdn1.iconfinder.com/data/icons/system-shade-circles/512/mac_os_X-16.png)](http://www.apple.com/osx/)

##### First install the following components (if you have not yet):

* [XCode](https://developer.apple.com/xcode/download/) 7.2 or higher
* [Homebrew](http://brew.sh/) the latest available version
* Command Line tools: run ```xcode-select --install``` in terminal

##### Run the following in terminal:

```sh
brew tap crossroadlabs/tap
brew install swift-express
```

## [Linux ![Linux](https://cdn1.iconfinder.com/data/icons/system-shade-circles/512/linux_tox-16.png)](http://www.linux.org/)

##### First install the following components (if you have not yet):

* [Linux](http://www.linux.org/), one of the following distributions will work:
	* [Ubuntu 15.10 (Wily Werewolf)](http://releases.ubuntu.com/15.10/)
	* [Ubuntu 14.04 (Trusty Tahr)](http://releases.ubuntu.com/14.04/)
* [Swift](https://swift.org/), the latest development snapshot from [here](https://swift.org/download/#latest-development-snapshots)
	* _You should have swift at least of 25.02.2016_
	* Installation instructions are [here](https://swift.org/getting-started/#on-linux)
* Dependency libraries:
	* If you are using Ubuntu 15.10, you are lucky. Just install the dependencies from `apt`:

```sh
sudo apt-get install libevhtp-dev libevent-dev libssl-dev
```

	* 

* [Dispatch](https://swift.org/core-libraries/#libdispatch) _(optional)_
	* For more information see dedicated [Dispatch installation section](#), please.

	
### Installing [Dispatch](https://swift.org/core-libraries/#libdispatch) on Linux

Dispatch is not available as a prebuilt package yet, so we have to build it from sources:

* Install prerequisites:

```sh
sudo apt-get install autoconf libtool pkg-config systemtap-sdt-dev libblocksruntime-dev libkqueue-dev libbsd-dev git make
```

* Clone dispatch repository and get into it:

```sh
git clone https://github.com/apple/swift-corelibs-libdispatch.git
cd swift-corelibs-libdispatch
```

* Initialize submodules:

```sh
git submodule init
git submodule update
```

* Generate build toolset:

```sh
sh ./autogen.sh
```

* Configure build:

```sh
./configure --with-swift-toolchain=<path-to-swift>/usr --prefix=<path-to-swift>/usr
```

`path-to-swift` whould point exactly to your swift distribution. Pay attension that you have to put `/usr` after it.

* Build:

```sh
make
```

* Install (*Don't worry, it will not install system wide*)

```sh
make install
```