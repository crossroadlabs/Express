//===--- ExecutionContext.swift -------------------------------------------===//
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
import BrightFutures
import ExecutionContext

private let cmain:ExecutionContextType = ExecutionContext.main

extension ExecutionContext {
    static let main = cmain
    static let user = global
    static let action = toContext(ExecutionContext(kind: .Parallel))
    static let render = toContext(ExecutionContext(kind: .Parallel))
    static let view = toContext(ExecutionContext(kind: .Serial))
    
    @noreturn class func run() {
        executionContextMain()
    }
}

extension String {
    func toNSString() -> NSString {
        #if !os(Linux)
            return self as NSString
        #else
            return self.bridge()
        #endif
    }
}