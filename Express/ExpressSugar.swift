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
import Future
import Regex

private func defaultUrlMatcher(path:String, method:String = HttpMethod.Any.rawValue) -> UrlMatcherType {
    return try! RegexUrlMatcher(method: method, pattern: path)
}

public extension Express {
    //sync
    //we need it to avoid recursion
    internal func handleInternal<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(matcher: defaultUrlMatcher(path: path, method: method), handler: handler)
    }
    
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>)  -> Void {
        self.handleInternal(method: method, path: path, handler: handler)
    }
    
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, regex:Regex, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(matcher: RegexUrlMatcher(method: method, regex: regex), handler: handler)
    }
    
    func all<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
    
    //async
    //we need it to avoid recursion
    internal func handleInternal<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handleInternal(matcher: defaultUrlMatcher(path: path, method: method), handler: handler)
    }
    
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handleInternal(method: method, path: path, handler: handler)
    }
    
    func handle<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(method:String, regex:Regex, handler:@escaping(Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handle(matcher: RegexUrlMatcher(method: method, regex: regex), handler: handler)
    }
    
    func all<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch<RequestContent : ConstructableContentType, ResponseContent : FlushableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<ResponseContent>>) -> Void {
        handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
    
    //action
    func handle<ResponseContent : FlushableContentType>(method:String, path:String, action:Action<ResponseContent>) -> Void {
        handle(matcher: defaultUrlMatcher(path: path, method: method), action: action)
    }
    
    func all<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        handle(method: HttpMethod.Any.rawValue, path: path, action: action)
    }
    
    func get<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        handle(method: HttpMethod.Get.rawValue, path: path, action: action)
    }
    
    func post<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        handle(method: HttpMethod.Post.rawValue, path: path, action: action)
    }
    
    func put<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        handle(method: HttpMethod.Put.rawValue, path: path, action: action)
    }
    
    func delete<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        handle(method: HttpMethod.Delete.rawValue, path: path, action: action)
    }
    
    func patch<ResponseContent : FlushableContentType>(path:String, action:Action<ResponseContent>) -> Void {
        handle(method: HttpMethod.Patch.rawValue, path: path, action: action)
    }
    
    //sync - simple req
    func handle<ResponseContent : FlushableContentType>(method:String, path:String, handler:@escaping (Request<AnyContent>) throws -> Action<ResponseContent>) -> Void {
        self.handleInternal(method: method, path: path, handler: handler)
    }
    
    func all<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>)throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>)throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>)throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<ResponseContent>) -> Void {
        self.handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
    
    //async - simple req
    func handle<ResponseContent : FlushableContentType>(method:String, path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handleInternal(method: method, path: path, handler: handler)
    }
    
    func all<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch<ResponseContent : FlushableContentType>(path:String, handler:@escaping(Request<AnyContent>) -> Future<Action<ResponseContent>>) -> Void {
        self.handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
    
    //sync - simple res
    func handle<RequestContent : ConstructableContentType>(method:String, path:String, handler:@escaping (Request<RequestContent>) throws -> Action<AnyContent>) -> Void {
        self.handleInternal(method: method, path: path, handler: handler)
    }
    
    func all<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
    
    //async - simple res
    func handle<RequestContent : ConstructableContentType>(method:String, path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handleInternal(method: method, path: path, handler: handler)
    }
    
    func all<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch<RequestContent : ConstructableContentType>(path:String, handler:@escaping (Request<RequestContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
    
    //sync - simple all
    func handle(method:String, path:String, handler:@escaping (Request<AnyContent>) throws -> Action<AnyContent>) -> Void {
        self.handleInternal(method: method, path: path, handler: handler)
    }
    
    func all(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch(path:String, handler:@escaping(Request<AnyContent>) throws -> Action<AnyContent>) -> Void {
        self.handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
    
    //async - simple all
    func handle(method:String, path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handleInternal(method: method, path: path, handler: handler)
    }
    
    func all(path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Any.rawValue, path: path, handler: handler)
    }
    
    func get(path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Get.rawValue, path: path, handler: handler)
    }
    
    func post(path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Post.rawValue, path: path, handler: handler)
    }
    
    func put(path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Put.rawValue, path: path, handler: handler)
    }
    
    func delete(path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Delete.rawValue, path: path, handler: handler)
    }
    
    func patch(path:String, handler:@escaping (Request<AnyContent>) -> Future<Action<AnyContent>>) -> Void {
        self.handle(method: HttpMethod.Patch.rawValue, path: path, handler: handler)
    }
}
