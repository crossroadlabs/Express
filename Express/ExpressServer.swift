//===--- ExpressServer.swift ----------------------------------------------===//
//
//Copyright (c) 2015-2016 Daniel Leping (dileping)
//
//This file is part of Swift Express.
//
//Swift Express is free software: you can redistribute it and/or modify
//it under the terms of the GNU Lesser General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//Swift Express is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with Swift Express.  If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//

import Foundation
import Result
import ExecutionContext
import Future

public extension Express {
    func listen(port:UInt16) -> Future<ServerType> {
        let server = HttpServer(app: self, port: port)
        return server.start()
    }
    
    func run() -> Never {
        #if os(Linux) && !dispatch
            print("Note: You have built Express without dispatch support. We have implemented this mode to support Linux developers while Dispatch for Linux is not available out of the box. Consider it to be development mode only and not suitable for production as it might cause occasional hanging and crashes. Still, there is a possibility to build Express with dispatch support (recommended for production use). Follow this link for more info: https://github.com/crossroadlabs/Express")
        #endif
        ExecutionContext.run()
    }
}
