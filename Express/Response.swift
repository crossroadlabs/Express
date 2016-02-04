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
import BrightFutures

//TODO: refactor
protocol HeadersAdjuster {
    typealias Content : FlushableContentType
    static func adjustHeaders(headers:Dictionary<String, String>, c:Content?) -> Dictionary<String, String>
}

public class Response<C : FlushableContentType> : HttpResponseHead, HeadersAdjuster {
    typealias Content = C
    
    let content:C?
    
    public init(status:UInt16, content:C? = nil, headers h:Dictionary<String, String> = Dictionary()) {
        self.content = content
        super.init(status: status, headers:Response<C>.adjustHeaders(h, c: content))
    }
    
    public override func flushTo(out:DataConsumerType) -> Future<Void, AnyError> {
        
        return super.flushTo(out).flatMap { ()->Future<Void,AnyError> in
            for c in self.content {
                return c.flushTo(out)
            }
            return Future(value: ())
        }.flatMap { ()->Future<Void,AnyError> in
            return future(ImmediateExecutionContext) {
                try out.dataEnd()
            }
        }
    }
    
    static func adjustHeaders(headers:Dictionary<String, String>, c:Content?) -> Dictionary<String, String> {
        let cType:String? = c.flatMap { content in
            switch content {
                case let ac as AnyContent: return ac.contentType
                default: return nil
            }
        }
        let h:Dictionary<String, String>? = cType.map { ct in
            var mHeaders = headers
            mHeaders.updateValue(ct, forKey: HttpHeader.ContentType.rawValue)
            return mHeaders
        }
        return h.getOrElse(headers)
    }
}