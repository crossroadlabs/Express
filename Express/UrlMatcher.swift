//===--- UrlMatcher.swift -------------------------------------------------===//
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

typealias UrlMatch = Dictionary<String,String>

protocol UrlMatcherType {
    func matches(pattern:String, url:String) -> UrlMatch?
}

class DumbUrlMatcher : UrlMatcherType {
    func matches(pattern:String, url:String) -> UrlMatch? {
        return pattern == url ? UrlMatch() : nil
    }
}

class DefaultUrlMatcher : UrlMatcherType {
    func matches(pattern:String, url:String) -> UrlMatch? {
        return pattern == url ? UrlMatch() : nil
    }
}

extension RouterType {
    func nextRoute(routeId:String, request:RequestHeadType?) -> (RouteType, UrlMatch)? {
        return request.flatMap { req in
            let matcher = self.matcher
            let url = req.path
            let method = req.method
            
            let index = routes.indexOf {routeId == $0.id}
            let route:(RouteType, UrlMatch)? = index.flatMap { i in
                let rest = routes.suffixFrom(i.successor())
                return rest.mapFirst { e in
                    if method != e.method {
                        return nil
                    }
                    guard let match = matcher.matches(e.path, url:url) else {
                        return nil
                    }
                    return (e, match)
                }
            }
            return route
        }
        
    }
}