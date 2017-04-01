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

public protocol UrlMatcherType {
    ///
    /// Matches path with a route and returns matched params if avalable.
    /// - Parameter path: path to match over
    /// - Returns: nil if route does not match. Matched params otherwise
    ///
    func match(method:String, path:String) -> [String: String]?
}

extension RouterType {
    func nextRoute(index:Array<RouteType>.Index?, request:RequestHeadType?) -> (RouteType, [String: String])? {
        return request.flatMap { req in
            let url = req.path
            let method = req.method
            
            let route:(RouteType, [String: String])? = index.flatMap { i in
                let rest = routes.suffix(from: i)
                return rest.mapFirst { e in
                    guard let match = e.matcher.match(method: method, path:url) else {
                        return nil
                    }
                    return (e, match)
                }
            }
            return route
        }
    }
    
    func nextRoute(routeId:String, request:RequestHeadType?) -> (RouteType, [String: String])? {
        return request.flatMap { req in
            
          
            
            let index = routes.index {routeId == $0.id}.map { $0 + 1 } // $0.successor
            return nextRoute(index: index, request: request)
        }
    }
    
    func firstRoute(request:RequestHeadType?) -> (RouteType, [String: String])? {
        return nextRoute(index: routes.startIndex, request: request)
    }
}
