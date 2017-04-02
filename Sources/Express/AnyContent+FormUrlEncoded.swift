//===--- AnyContent+FormUrlEncoded.swift ----------------------------------===//
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

public extension AnyContent {
    func asFormUrlEncoded() -> Dictionary<String, Array<String>>? {
        return contentType.filter {$0 == "application/x-www-form-urlencoded"}.flatMap { _ in
            self.asText()
        }.map(evhtp_parse_query)
    }
}

public extension Request where C : AnyContent {
    public func mergedQuery() -> Dictionary<String, Array<String>> {
        guard let bodyQuery = body?.asFormUrlEncoded() else {
            return query
        }
        
        let urlKeys = Set(query.keys)
        let keys = Array(urlKeys.union(bodyQuery.keys))
        
        let merged = keys.map { key -> (String, Array<String>) in
            let allValues = query[key].map { urlValues in
                bodyQuery[key].flatMap { bodyValues in
                    return urlValues + bodyValues
                }.getOrElse {
                    urlValues
                }
            }.getOrElse {
                bodyQuery[key]!
            }
            
            return (key, allValues)
        }
        return toMap(array: merged)
    }
}
