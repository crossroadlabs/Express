//===--- Headers.swift ----------------------------------------------------===//
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

public enum HttpHeader : String {
    case ContentType = "Content-Type"
    case ContentLength = "Content-Length"
    
    func header(headers:Dictionary<String,String>) -> String? {
        return headers[self.rawValue]
    }
    
    func headerInt(headers:Dictionary<String,String>) -> Int? {
        return header(headers: headers).flatMap { str in Int(str) }
    }
}

public protocol HttpHeadType {
    var headers:Dictionary<String, String> {get}
}

public class HttpHead : HttpHeadType {
    public let headers:Dictionary<String, String>
    
    init(head:HttpHeadType) {
        headers = head.headers
    }
    
    init(headers:Dictionary<String, String>) {
        self.headers = headers
    }
}

public protocol HttpResponseHeadType : HttpHeadType {
    var status:UInt16 {get}
}

public class HttpResponseHead : HttpHead, HttpResponseHeadType, FlushableType {
    public let status:UInt16
    
    init(status:UInt16, head:HttpHeadType) {
        self.status = status
        super.init(head: head)
    }
    
    init(status:UInt16, headers:Dictionary<String, String>) {
        self.status = status
        super.init(headers: headers)
    }
    
    //all the code below should be moved to Streams+Headers and made as an extension
    //unfortunately swift does not allow to override functions introduced in extensions yet
    //should be moved as soon as the feature is implemented in swift
    public func flushTo(out:DataConsumerType) -> Future<Void> {
        if let headOut = out as? ResponseHeadDataConsumerType {
            return headOut.consume(head: self)
        } else {
            return out.consume(data: serializeHead())
        }
    }
    
    func serializeHead() -> Array<UInt8> {
        //TODO: move to real serializer
        var r = "HTTP/1.1 " + status.description + " OK\n"
        for header in headers {
            r += header.0 + ": " + header.1 + "\n"
        }
        r += "\n"
        return Array(r.utf8)
    }
}
