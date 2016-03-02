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
import BrightFutures

public protocol StaticDataProviderType {
    init(root:String)
    
    func etag(file:String) throws -> String
    func data(file:String) throws -> FlushableContentType
}

public class StaticFileProvider : StaticDataProviderType {
    let root:String
    let fm = NSFileManager.defaultManager()
    
    public required init(root:String) {
        self.root = root
    }
    
    func fullPath(file:String) -> String {
        return root.bridge().stringByAppendingPathComponent(file)
    }
    
    public func etag(file:String) throws -> String {
        let file = fullPath(file)
        
        let attributes = try fm.attributesOfItemAtPath(file)
        
        guard let modificationDate = (attributes[NSFileModificationDate].flatMap{$0 as? NSDate}) else {
            //TODO: throw different error
            throw ExpressError.PageNotFound(path: file)
        }
        
        let timestamp = UInt64(modificationDate.timeIntervalSince1970 * 1000 * 1000)
        
        //TODO: use MD5 of fileFromURI + timestamp
        let etag = "\"" + String(timestamp) + "\""
        
        return etag
    }
    
    public func data(file:String) throws -> FlushableContentType {
        let file = fullPath(file)
        
        var isDir = ObjCBool(false)
        if !fm.fileExistsAtPath(file, isDirectory: &isDir) || isDir.boolValue {
            //TODO: implement file directory index (WebDav)
            throw ExpressError.PageNotFound(path: file)
        }
        
        //TODO: get rid of NS
        guard let data = NSData(contentsOfFile: file) else {
            throw ExpressError.FileNotFound(filename: file)
        }
        
        let count = data.length / sizeof(UInt8)
        // create array of appropriate length:
        var array = [UInt8](count: count, repeatedValue: 0)
        
        // copy bytes into array
        data.getBytes(&array, length:count * sizeof(UInt8))
        
        let ext = file.bridge().pathExtension
        
        guard let content = AnyContent(data: array, contentType: MIME.extMime[ext]) else {
            throw ExpressError.FileNotFound(filename: file)
        }
        
        return content
    }
}

public class BaseStaticAction<C : FlushableContentType> : Action<C>, IntermediateActionType {
    let param:String
    let dataProvider:StaticDataProviderType
    let cacheControl:CacheControl
    
    public init(param:String, dataProvider:StaticDataProviderType, cacheControl:CacheControl = .NoCache) {
        self.param = param
        self.dataProvider = dataProvider
        self.cacheControl = cacheControl
    }
    
    public func nextAction<RequestContent : ConstructableContentType>(app:Express, routeId:String, request:Request<RequestContent>, out:DataConsumerType) -> Future<AbstractActionType, AnyError> {
        return future { ()->AbstractActionType in
            if request.method != HttpMethod.Get.rawValue {
                return Action<AnyContent>.chain()
            }
            
            guard let fileFromURI = request.params[self.param] else {
                print("Can not find ", self.param, " group in regex")
                return Action<AnyContent>.chain()
            }
            
            var headers = [String: String]()
            
            headers.updateWithHeader(self.cacheControl)
            
            do {
                let etag = try self.dataProvider.etag(fileFromURI)
                headers.updateValue(etag, forKey: "ETag")
                
                if let requestETag = request.headers["If-None-Match"] {
                    if requestETag == etag {
                        return Action<AnyContent>.response(.NotModified, content: nil, headers: headers)
                    }
                }
                
                let content = try self.dataProvider.data(fileFromURI)
                
                let flushableContent = FlushableContent(content: content)
                
                return Action.ok(flushableContent, headers: headers)
            } catch ExpressError.PageNotFound(path: _) {
                return Action<AnyContent>.chain()
            } catch ExpressError.FileNotFound(filename: _) {
                return Action<AnyContent>.chain()
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