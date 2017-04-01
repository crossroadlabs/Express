//===--- Response.swift ---------------------------------------------------===//
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
import ExecutionContext

//TODO: refactor
protocol HeadersAdjuster {
    associatedtype Content : FlushableContentType
    static func adjustHeaders(headers:Dictionary<String, String>, c:ContentType?) -> Dictionary<String, String>
}

public protocol ResponseType : HttpResponseHeadType {
    var content:FlushableContentType? {get}
}

public class Response<C : FlushableContentType> : HttpResponseHead, HeadersAdjuster, ResponseType {
    typealias Content = C
    
    public let content:FlushableContentType?
    
    public convenience init(status:StatusCode, content:C? = nil, headers:Dictionary<String, String> = Dictionary()) {
        self.init(status: status.rawValue, content: content, headers: headers)
    }
    
    public init(status:UInt16, content:C? = nil, headers:Dictionary<String, String> = Dictionary()) {
        self.content = content
        super.init(status: status, headers:Response<C>.adjustHeaders(headers: headers, c: content))
    }
    
    public override func flushTo(out:DataConsumerType) -> Future<Void> {
        let content = self.content
        return super.flushTo(out: out).flatMap { ()->Future<Void> in
            return content.map {$0.flushTo(out: out)} ?? Future(value: ())
        }.flatMap { ()->Future<Void> in
            return future(context: immediate) {
                try out.dataEnd()
            }
        }
    }
    
    static func adjustHeaders(headers:Dictionary<String, String>, c:ContentType?) -> Dictionary<String, String> {
        let cType:String? = c.flatMap { content in
            content.contentType
        }
        let h:Dictionary<String, String>? = cType.map { ct in
            var mHeaders = headers
            mHeaders.updateValue(ct, forKey: HttpHeader.ContentType.rawValue)
            return mHeaders
        }
        return h.getOrElse(el: headers)
    }
}

extension Response where C : FlushableContent {
    convenience init(status:StatusCode, content:FlushableContentType?, headers:Dictionary<String, String> = Dictionary()) {
        let content = content.map { content in
            C(content: content)
        }
        self.init(status: status, content: content, headers: headers)
    }
}
