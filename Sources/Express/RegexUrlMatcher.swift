//===--- RegexUrlMatcher.swift --------------------------------------------===//
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

import Regex
import PathToRegex

public class RegexUrlMatcher : UrlMatcherType {
    private let method:String
    private let regex:Regex
    
    public init(method:String, regex:Regex) {
        self.method = method
        self.regex = regex
    }
    
    public convenience init(method:String, pattern:String) throws {
        self.init(method: method, regex: try Regex(path: pattern))
    }
    
    ///
    /// Matches path with a route and returns matched params if avalable.
    /// - Parameter path: path to match over
    /// - Returns: nil if route does not match. Matched params otherwise
    ///
    public func match(method:String, path:String) -> [String: String]? {
        if self.method != "*" && self.method != method {
            return nil
        }
        guard let found = regex.findFirst(in: path) else {
            return nil
        }
        let valsArray = regex.groupNames.map { name in
            (name, found.group(named: name))
        }.filter {$0.1 != nil} . map { tuple in
            (tuple.0, tuple.1!)
        }
        return toMap(array: valsArray)
    }
}
