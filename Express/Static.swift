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
    
    public init(path:String) {
        self.path = path
    }
    
    public func nextAction<RequestContent : ConstructableContentType>(app:Express, routeId:String, request:Request<RequestContent>, out:DataConsumerType) -> Future<AbstractActionType, AnyError> {
        return future { ()->AbstractActionType in
            if request.method != HttpMethod.Get.rawValue {
                return Action<AnyContent>.chain()
            }
            //yes here we are completely sure route id exists
            let route = app.routeForId(routeId)!
            
            var base = route.path
            
            //TODO: proper path matching
            //reach last *
            while !base.hasSuffix("*") {
                base.removeAtIndex(base.endIndex.predecessor())
            }
            
            //get rid of last *
            while base.hasSuffix("*") {
                base.removeAtIndex(base.endIndex.predecessor())
            }
            
            let fileFromURI = request.path.substringFromIndex(base.endIndex)
            
            //TODO: get rid of NSs
            let file = (self.path as NSString).stringByAppendingPathComponent(fileFromURI)
            let ext = (file as NSString).pathExtension
            
            let fm = NSFileManager.defaultManager()
            
            var isDir = ObjCBool(false)
            if !fm.fileExistsAtPath(file, isDirectory: &isDir) || isDir.boolValue {
                //TODO: implement file directory index (WebDav)
                return Action<AnyContent>.chain()
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
            
            return Action<AnyContent>.ok(content)
        }
    }
}