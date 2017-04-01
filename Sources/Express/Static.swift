//===--- Static.swift -----------------------------------------------------===//
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

public protocol StaticDataProviderType {
    func etag(file:String) -> Future<String>
    func data(app:Express, file:String) -> Future<FlushableContentType>
}

public class StaticFileProvider : StaticDataProviderType {
    let root:String
    let fm = FileManager.default
    
    public init(root:String) {
        self.root = root
    }
    
    func fullPath(file:String) -> String {
        return root.bridge().appendingPathComponent(file)
    }
    
    private func attributes(file:String) throws -> [FileAttributeKey : Any] {
        do {
           
            return try self.fm.attributesOfItem(atPath: file)
        } catch {
            throw ExpressError.FileNotFound(filename: file)
        }
    }
    
    public func etag(file:String) -> Future<String> {
        let file = fullPath(file: file)
        
        return future {
            let attributes = try self.attributes(file: file)
            
            guard let modificationDate = (attributes[FileAttributeKey.modificationDate].flatMap{$0 as? NSDate}) else {
                //TODO: throw different error
                throw ExpressError.PageNotFound(path: file)
            }
            
            let timestamp = UInt64(modificationDate.timeIntervalSince1970 * 1000 * 1000)
            
            //TODO: use MD5 of fileFromURI + timestamp
            let etag = "\"" + String(timestamp) + "\""
            
            return etag
        }
    }
    
    public func data(app:Express, file:String) -> Future<FlushableContentType> {
        let file = fullPath(file: file)
        
        return future {
            var isDir = ObjCBool(false)
            if !self.fm.fileExists(atPath: file, isDirectory: &isDir) || isDir.boolValue {
                //TODO: implement file directory index (WebDav)
                throw ExpressError.PageNotFound(path: file)
            }
            
            //TODO: get rid of NS
            guard let data = NSData(contentsOfFile: file) else {
                throw ExpressError.FileNotFound(filename: file)
            }
            
            let count = data.length / MemoryLayout<UInt8>.size
            // create array of appropriate length:
            var array = [UInt8](repeating: 0, count: count)
            
            // copy bytes into array
            data.getBytes(&array, length:count * MemoryLayout<UInt8>.size)
            
            let ext = file.bridge().pathExtension
            
            guard let content = AnyContent(data: array, contentType: MIME.extMime[ext]) else {
                throw ExpressError.FileNotFound(filename: file)
            }
            
            return content
        }
    }
}

public class BaseStaticAction<C : FlushableContentType> : Action<C>, IntermediateActionType {
    let param:String
    let dataProvider:StaticDataProviderType
    let cacheControl:CacheControl
    let headers:[String: String]
    
    public init(param:String, dataProvider:StaticDataProviderType, cacheControl:CacheControl = .NoCache) {
        self.param = param
        self.dataProvider = dataProvider
        self.cacheControl = cacheControl
        
        var headers = [String: String]()
        headers.updateWithHeader(header: self.cacheControl)
        
        self.headers = headers
    }
    
    public func nextAction<RequestContent : ConstructableContentType>(request:Request<RequestContent>) -> Future<(AbstractActionType, Request<RequestContent>?)> {
        
        if request.method != HttpMethod.Get.rawValue {
            return Future<(AbstractActionType, Request<RequestContent>?)>(value: (Action<AnyContent>.chain(), nil))
        }
        
        guard let fileFromURI = request.params[self.param] else {
            print("Can not find ", self.param, " group in regex")
            return Future<(AbstractActionType, Request<RequestContent>?)>(value: (Action<AnyContent>.chain(), nil))
        }
        
        let etag = self.dataProvider.etag(file: fileFromURI)
        
        return etag.flatMap { etag -> Future<(AbstractActionType, Request<RequestContent>?)> in
            let headers = self.headers ++ ["ETag": etag]
            
            if let requestETag = request.headers["If-None-Match"] {
                if requestETag == etag {
                    let action = Action<AnyContent>.response(status: .NotModified, content: nil, headers: headers)
                    return Future<(AbstractActionType, Request<RequestContent>?)>(value: (action, nil))
                }
            }
            
            let content = self.dataProvider.data(app: request.app, file: fileFromURI)
            
            return content.map { content in
                let flushableContent = FlushableContent(content: content)
                
                return (Action.ok(flushableContent, headers: headers), nil)
            }
        }.recoverWith { e in
            switch e {
            case ExpressError.PageNotFound(path: _): fallthrough
            case ExpressError.FileNotFound(filename: _):
                return Future(value: (Action<AnyContent>.chain(), nil))
            default:
                return Future(error:  e)
            }
        }
    }
}

public class StaticAction : BaseStaticAction<AnyContent> {

    public init(path:String, param:String, cacheControl:CacheControl = .NoCache) {
        let dataProvider = StaticFileProvider(root: path)
        super.init(param: param, dataProvider: dataProvider, cacheControl: cacheControl)
    }
    
}
