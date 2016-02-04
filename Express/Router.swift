//===--- Router.swift -----------------------------------------------------===//
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

protocol RouteType {
    var id:String {get}
    var method:String {get}
    var path:String {get}
    var factory:TransactionFactory {get}
}

class Route : RouteType {
    let id:String
    let method:String
    let path:String
    let factory:TransactionFactory
    
    init(id:String, method:String, path:String, factory:TransactionFactory) {
        self.id = id
        self.method = method
        self.path = path
        self.factory = factory
    }
}

protocol RouterType {
    var routes:Array<RouteType> {get}
    var matcher:UrlMatcherType {get}
    
    func routeForId(id:String) -> RouteType?
}