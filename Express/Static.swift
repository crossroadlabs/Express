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

public class StaticAction : Action<AnyContent>, IntermediateActionType {
    let path:String
    let param:String
    
    public init(path:String, param:String) {
        self.path = path
        self.param = param
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
            
            //TODO: get rid of NSs
            let file = self.path.bridge().stringByAppendingPathComponent(fileFromURI)
            let ext = file.bridge().pathExtension
            
            let fm = NSFileManager.defaultManager()
            
            var isDir = ObjCBool(false)
            if !fm.fileExistsAtPath(file, isDirectory: &isDir) || isDir.boolValue {
                //TODO: implement file directory index (WebDav)
                return Action<AnyContent>.chain()
            }
            
            let attributes = try fm.attributesOfItemAtPath(file)
            
            var headers = [String: String]()
            
            if let modificationDate = (attributes[NSFileModificationDate].flatMap{$0 as? NSDate}) {
                let timestamp = UInt64(modificationDate.timeIntervalSinceReferenceDate * 1000 * 1000)
                //TODO: use MD5 of fileFromURI + timestamp
                let etag = "\"" + String(timestamp) + "\""
                
                headers.updateValue(etag, forKey: "ETag")
                
                if let requestETag = request.headers["If-None-Match"] {
                    if requestETag == etag {
                        return Action<AnyContent>.response(.NotModified, content: nil, headers: headers)
                    }
                }
            }
            
            //TODO: get rid of NS
            guard let data = NSData(contentsOfFile: file) else {
                return Action<AnyContent>.chain()
            }
            
            let count = data.length / sizeof(UInt8)
            // create array of appropriate length:
            var array = [UInt8](count: count, repeatedValue: 0)
            
            // copy bytes into array
            data.getBytes(&array, length:count * sizeof(UInt8))
            
            //TODO: implement mime types
            let content = AnyContent(data: array, contentType: MIME.extMime[ext])
            
            return Action<AnyContent>.ok(content, headers: headers)
        }
    }
}