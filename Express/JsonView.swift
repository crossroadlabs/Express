//===--- JsonView.swift ---------------------------------------------------===//
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
import SwiftyJSON

public protocol JSONConvertible {
    func toJSON() -> JSON?
}

extension Bool : JSONConvertible {
    public func toJSON() -> JSON? {
        return JSON(self)
    }
}

extension Double : JSONConvertible {
    public func toJSON() -> JSON? {
        return JSON(self)
    }
}

extension Int : JSONConvertible {
    public func toJSON() -> JSON? {
        return JSON(self)
    }
}

extension String : JSONConvertible {
    public func toJSON() -> JSON? {
        return JSON(self)
    }
}

extension Array : JSONConvertible {
    public func toJSON() -> JSON? {
        return JSON(self.flatMap { $0 as? JSONConvertible }.flatMap {$0.toJSON()})
    }
}

extension Dictionary : JSONConvertible {
    public func toJSON() -> JSON? {
        let normalized = self.map {(String(describing: $0), $1)}.flatMap { (k, v) in
            (v as? JSONConvertible).map {(k, $0)}
        }
        return JSON(toMap(array: normalized.flatMap { (k, v) in
            v.toJSON().map {(k, $0)}
        }))
    }
}

extension Optional {
    public func toJSON() -> JSON? {
        return self.flatMap{$0 as? JSONConvertible}.flatMap{$0.toJSON()}
    }
}

public class JsonView : NamedViewType {
    public static let name:String = "json"
    public let name:String = JsonView.name
    
    public init() {
    }
    
    public func render<Context>(context:Context?) throws -> FlushableContentType {
        //TODO: implement reflection
        let json = context.flatMap{$0 as? JSONConvertible}.flatMap { $0.toJSON() }
        
        //TODO: avoid string path
        guard let render = json?.rawString() else {
            throw ExpressError.Render(description: "unable to render json: " + context.flatMap{String(describing: $0)}.getOrElse(el: "None"), line: nil, cause: nil)
        }
        return AnyContent(str:render, contentType: "application/json")!
    }
}
