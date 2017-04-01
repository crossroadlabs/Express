//===--- Functional.swift -------------------------------------------------===//
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

func toMap<A : Hashable, B>(array:Array<(A, B)>) -> Dictionary<A, B> {
    var dict = Dictionary<A, B>()
    for (k, v) in array {
        dict[k] = v
    }
    return dict
}

extension Sequence {
    func fold<B>(initial:B, f:(B, Iterator.Element)->B) -> B {
        var b:B = initial
        forEach { e in
            b = f(b, e)
        }
        return b
    }
    
    func findFirst(f:(Iterator.Element)->Bool) -> Iterator.Element? {
        for e in self {
            if(f(e)) {
                return e
            }
        }
        return nil
    }
    
    func mapFirst<B>(f:(Iterator.Element)->B?) -> B? {
        for e in self {
            let b = f(e)
            if b != nil {
                return b
            }
        }
        return nil
    }
}

/*Just an example


let arr = [1, 2, 4]

let folded = arr.fold(1) { b, e in
    return b+e
}

print("B: ", folded)*/

public extension Optional {
    func getOrElse( el:@autoclosure () -> Wrapped) -> Wrapped {
        switch self {
            case .some(let value): return value
            default: return el()
        }
    }
    
    func getOrElse(el:() -> Wrapped) -> Wrapped {
        switch self {
            case .some(let value): return value
            default: return el()
        }
    }
}

public extension Dictionary {
    mutating func getOrInsert(key:Key, f:@autoclosure ()->Value) -> Value {
        return getOrInsert(key: key, f: f)
    }
    
    mutating func getOrInsert(key:Key, f:()->Value) -> Value {
        guard let stored = self[key] else {
            let value = f()
            self[key] = value
            return value
        }
        return stored
    }
    
    mutating func getOrInsert(key:Key, f:@autoclosure () throws ->Value) throws -> Value {
        return try getOrInsert(key: key, f: f)
    }
    
    mutating func getOrInsert(key:Key, f:() throws -> Value) throws -> Value {
        guard let stored = self[key] else {
            let value = try f()
            self[key] = value
            return value
        }
        return stored
    }
}

public extension Dictionary {
    func map<K : Hashable, V>( transform: ((Key, Value)) throws -> (K, V)) rethrows -> Dictionary<K, V> {
        var result = Dictionary<K, V>()
        for it in self {
            let (k, v) = try transform(it)
            result[k] = v
        }
        return result
    }
}

infix operator ++ { associativity left precedence 160 }

public func ++ <Key: Hashable, Value>(left:Dictionary<Key, Value>, right:Dictionary<Key, Value>) -> Dictionary<Key, Value> {
    var new = left
    for (k, v) in right {
        new[k] = v
    }
    return new
}
