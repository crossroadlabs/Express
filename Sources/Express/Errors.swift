//===--- Errors.swift -----------------------------------------------------===//
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

public protocol ExpressErrorType : Error {
}

public enum ExpressError : Error {
    case NotImplemented(description:String)
    case FileNotFound(filename:String)
    case PageNotFound(path:String)
    case RouteNotFound(path:String)
    case NoSuchView(name:String)
    case Render(description:String, line:Int?, cause:Error?)
}

func ExpressErrorHandler(e:Error) -> AbstractActionType? {
    guard let e = e as? ExpressError else {
        return nil
    }
    
    switch e {
        case .NotImplemented(let description): return Action<AnyContent>.internalServerError(description: description)
        case .FileNotFound(let filename): return Action<AnyContent>.internalServerError(description: "File not found: " + filename)
        case .NoSuchView(let name): return Action<AnyContent>.internalServerError(description: "View not found: " + name)
        case .PageNotFound(let path): return Action<AnyContent>.notFound(filename: path)
        case .RouteNotFound(let path): return Action<AnyContent>.routeNotFound(path: path)
        case .Render(var description, line: let line, cause: let e):
            description += "\n\n"
            if (line != nil) {
                description.append("At line:" + line!.description + "\n\n")
            }
            if (e != nil) {
                description.append("With error: " + e.debugDescription)
            }
            return Action<AnyContent>.internalServerError(description: "View not found: " + description)
    }
}
