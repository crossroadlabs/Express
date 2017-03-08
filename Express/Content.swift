//===--- Content.swift ----------------------------------------------------===//
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

public protocol ContentFactoryType : DataConsumerType {
    associatedtype Content
    
    init(response:RequestHeadType)
    
    func tryConsume(content:ContentType) -> Bool
    func content() -> Future<Content>
}

public protocol ContentType {
    var contentType:String? {get}
}

public protocol ConstructableContentType : ContentType {
    associatedtype Factory: ContentFactoryType
}

public class ContentFactoryBase {
    public let head:RequestHeadType
    
    public required init(response:RequestHeadType) {
        head = response
    }
}

public protocol FlushableContentType : ContentType, FlushableType {
}

public class FlushableContent : FlushableContentType {
    let content:FlushableContentType
    public var contentType:String? {
        get {
            return content.contentType
        }
    }
    
    public required init(content:FlushableContentType) {
        self.content = content
    }
    
    public func flushTo(out:DataConsumerType) -> Future<Void> {
        return content.flushTo(out: out)
    }
}

public class AbstractContentFactory<T> : ContentFactoryBase, ContentFactoryType {
    public typealias Content = T
    var promise:Promise<Content>
    
    public required init(response:RequestHeadType) {
        promise = Promise()
        super.init(response: response)
    }
    
    public func consume(data:Array<UInt8>) -> Future<Void> {
        return future(context: immediate) {
            throw ExpressError.NotImplemented(description: "Not implemented consume in " + Mirror(reflecting: self).description)
        }
    }
    
    public func dataEnd() throws {
        throw ExpressError.NotImplemented(description: "Not implemented consume in " + Mirror(reflecting: self).description)
    }
    
    public func tryConsume(content: ContentType) -> Bool {
        switch content {
        case let match as Content:
            //TODO: check this? return value?
            promise.trySuccess(value: match)
            return true
        default:
            return false
        }
    }
    
    public func content() -> Future<Content> {
        return promise.future
    }
}
