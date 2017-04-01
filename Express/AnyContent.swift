//===--- AnyContent.swift -------------------------------------------------===//
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

public class AnyContentFactory : AbstractContentFactory<AnyContent> {
    private var data:Array<UInt8> = []
    
    public required init(response:RequestHeadType) {
        super.init(response: response)
    }
    
    func resolve() {
        promise.trySuccess(value: AnyContent(data: self.data, contentType: head.contentType)!)
    }
    
    public override func consume(data:Array<UInt8>) -> Future<Void> {
        return future(context: immediate) {
            self.data += data
            if let length = self.head.contentLength {
                if(self.data.count >= length) {
                    self.resolve()
                }
            }
        }
    }
    
    public override func dataEnd() {
        resolve()
    }
}

public class AnyContent : ConstructableContentType, FlushableContentType {
    public typealias Factory = AnyContentFactory
    let data:Array<UInt8>
    public let contentType:String?
    
    public init?(data:Array<UInt8>?, contentType:String?) {
        guard let data = data else {
            self.data = []
            self.contentType = nil
            return nil
        }
        self.data = data
        self.contentType = contentType
    }
    
    public func flushTo(out: DataConsumerType) -> Future<Void> {
        return out.consume(data: data)
    }
}

// textual extensions
public extension AnyContent {
    public convenience init?(str:String?, contentType:String? = nil) {
        guard let str = str else {
            return nil
        }
        self.init(data: Array(str.utf8), contentType: contentType)
    }
    
    func asText() -> String? {
        return String(bytes: data, encoding: String.Encoding.utf8)
    }
}

// raw data extensions
public extension AnyContent {
    func asRaw() -> [UInt8]? {
        return data
    }
}
