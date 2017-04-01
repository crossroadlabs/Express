//===--- Request.swift ----------------------------------------------------===//
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

public protocol RequestHeadersType {
    var contentLength:Int? {get}
    var contentType:String? {get}
}

public protocol RequestHeadType : HttpHeadType, RequestHeadersType {
    // HTTP method
    var method:String {get}
    
    // HTTP protocol version
    var version:String {get}
    
    // address of the client
    var remoteAddress:String {get}
    
    // if the connection is sequre (HTTPS)
    var secure: Bool {get}
    
    // full URI component from request
    var uri:String {get}
    
    // request path without query string
    var path:String {get}
    
    // parsed query string {get}
    var query:Dictionary<String,Array<String>> {get}
    
    // name params parsed from the URL pattern
    var params:Dictionary<String,String> {get}
    
    var headers:Dictionary<String, String> {get}
    
    init(app:Express, method:String, version:String, remoteAddress:String, secure: Bool, uri:String, path:String, query:Dictionary<String,Array<String>>, headers:Dictionary<String, String>, params:Dictionary<String, String>)
}

public class RequestHead : HttpHead, RequestHeadType {
    public let method:String
    public let version:String
    public let remoteAddress:String
    public let secure: Bool
    public let uri:String
    public let path:String
    public let query:Dictionary<String,Array<String>>
    public let params:Dictionary<String,String>
    
    public let contentLength:Int?
    public let contentType:String?
    
    public init(head:RequestHeadType) {
        contentLength = head.contentLength
        contentType = head.contentType
        remoteAddress = head.remoteAddress
        secure = head.secure
        uri = head.uri
        path = head.path
        query = head.query
        params = head.params
        
        method = head.method
        version = head.version
        super.init(head: head)
    }
    
    public required init(app:Express, method:String, version:String, remoteAddress:String, secure: Bool, uri:String, path:String, query:Dictionary<String,Array<String>>, headers:Dictionary<String, String>, params:Dictionary<String, String>) {
        self.method = method
        self.version = version
        self.remoteAddress = remoteAddress
        self.secure = secure
        self.uri = uri
        self.path = path
        self.query = query
        self.params = params
        
        contentLength = HttpHeader.ContentLength.headerInt(headers: headers)
        contentType = HttpHeader.ContentType.header(headers: headers)
        super.init(headers: headers)
    }
}

public protocol RequestType : RequestHeadType, AppContext {
    associatedtype Content
    
    var body:Content? {get}
}

public class Request<C> : RequestHead, RequestType {
    public let app:Express
    public let body:Content?
    
    public typealias Content = C
    
    init(app:Express, head: RequestHeadType, body:Content?) {
        self.app = app
        self.body = body
        super.init(head: head)
    }
    
    public required init(app:Express, method:String, version:String, remoteAddress:String, secure: Bool, uri:String, path:String, query:Dictionary<String,Array<String>>, headers:Dictionary<String, String>, params:Dictionary<String, String>) {
        self.app = app
        self.body = nil
        super.init(app: app, method: method, version: version, remoteAddress: remoteAddress, secure: secure, uri: uri, path: path, query: query, headers: headers, params: params)
    }
}

extension RequestHeadType {
    func withParams(params:Dictionary<String, String>, app:Express) -> Self {
        return Self(app: app, method: self.method, version: self.version, remoteAddress: self.remoteAddress, secure: self.secure, uri: self.uri, path: self.path, query: self.query, headers: headers, params: params)
    }
}
