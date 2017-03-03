//===--- CacheControl.swift -------------------------------------------------===//
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

public protocol HeaderType {
    var key:String {get}
    var value:String {get}
    
    static var key:String {get}
}

public protocol StringType : Hashable {
    static func fromString(string:String) -> Self
}

extension String : StringType {
    public static func fromString(string:String) -> String {
        return string
    }
}

public extension Dictionary where Key : StringType, Value : StringType {
    public mutating func updateWithHeader(header:HeaderType) {
        self.updateValue(Value.fromString(string: header.value), forKey: Key.fromString(string: header.key))
    }
}

public enum CacheControl {
    case NoStore
    case NoCache
    case Private(maxAge:UInt)
    case Public(maxAge:UInt)
}

extension CacheControl : HeaderType {
    public static let key:String = "Cache-Control"
    
    public var key:String {
        get {
            return CacheControl.key
        }
    }
    
    public var value:String {
        get {
            switch self {
            case .NoStore: return "no-store"
            case .NoCache: return "no-cache"
            case .Public(let maxAge):
                return "max-age=" + String(maxAge)
            case .Private(let maxAge):
                return "private, max-age=" + String(maxAge)
            }
        }
    }
}
