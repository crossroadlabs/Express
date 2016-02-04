//===--- ExpressSugar.swift -----------------------------------------------===//
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

public extension Express {
    
    
    //sync
    func handle<ResponseContent : FlushableContentType>(method:String, path:String, handler:Request<AnyContent> throws -> Action<ResponseContent>) -> Void {
        self.handleInternal(method, path: path, handler: handler)
    }
    
    func get<ResponseContent : FlushableContentType>(path:String, handler:Request<AnyContent> throws -> Action<ResponseContent>) -> Void {
        self.handle(HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<ResponseContent : FlushableContentType>(path:String, handler:Request<AnyContent> throws -> Action<ResponseContent>) -> Void {
        self.handle(HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    //async
    func handle<ResponseContent : FlushableContentType, E: ErrorType>(method:String, path:String, handler:Request<AnyContent> -> Future<Action<ResponseContent>, E>) -> Void {
        handleInternal(method, path: path, handler: handler)
    }
    
    func get<ResponseContent : FlushableContentType, E: ErrorType>(path:String, handler:Request<AnyContent> -> Future<Action<ResponseContent>, E>) -> Void {
        self.handle(HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<ResponseContent : FlushableContentType, E: ErrorType>(path:String, handler:Request<AnyContent> -> Future<Action<ResponseContent>, E>) -> Void {
        self.handle(HttpMethod.Post.rawValue, path: path, handler: handler)
    }
}