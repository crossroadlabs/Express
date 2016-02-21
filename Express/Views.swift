//===--- Views.swift ------------------------------------------------------===//
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
import ExecutionContext
import BrightFutures
import Result

public class Views {
    //TODO: move hardcode to config
    internal var views:Dictionary<String, ViewType> = Dictionary()
    internal var paths:Array<String> = ["./views"]
    internal var engines:Dictionary<String, ViewEngineType> = Dictionary()
    internal let viewContext = ExecutionContext.view
    internal let renderContext = ExecutionContext.render
    
    public var cache:Bool = false
    func cacheView(viewName:String, view:Future<ViewType, AnyError>) -> Future<ViewType, AnyError> {
        if cache {
            return view.andThen(context: self.viewContext) { result in
                if let val = try? result.dematerialize() {
                    self.views[viewName] = val
                }
            }
        } else {
            return view
        }
    }
    
    public func register(path:String) {
        future(viewContext) {
            self.paths.append(path)
        }
    }
    
    public func register(view: ViewType, name:String) {
        future(viewContext) {
            self.views[name] = view
        }
    }
    
    public func register(view: NamedViewType) {
        register(view, name: view.name)
    }
    
    public func register(engine: ViewEngineType) {
        future(viewContext) {
            let exts = engine.extensions()
            for ext in exts {
                self.engines[ext] = engine
            }
        }
    }
    
    func view(viewName:String, resolver: (String)->Future<ViewType, AnyError>) -> Future<ViewType, AnyError> {
        return future(context: viewContext) {
            Result<ViewType?, AnyError>(value: self.views[viewName])
        }.flatMap { (view:ViewType?) -> Future<ViewType, AnyError> in
            return view.map { view in
                Future<ViewType, AnyError>(value: view)
            }.getOrElse {
                return self.cacheView(viewName, view: resolver(viewName))
            }
        }
    }
    
    func view(viewName:String) -> Future<ViewType, AnyError> {
        return view(viewName) { viewName in
            return future(context: self.viewContext) {
                let fileManager = NSFileManager.defaultManager()
                let exts = self.engines.keys
                
                let combinedData = self.paths.map { path in
                    exts.map { ext in
                        (ext, path.toNSString().stringByAppendingPathComponent(viewName) + "." + ext)
                    }
                }.flatten()
                
                return combinedData.findFirst { (ext, file) -> Bool in
                    // get first found template (ext, file)
                    //TODO: (path as NSString).stringByAppendingPathComponent(view) reimplement
                    var isDir = ObjCBool(false)
                    return fileManager.fileExistsAtPath(file, isDirectory: &isDir) && !isDir.boolValue
                }.flatMap { (ext, file) -> (ViewEngineType, String)? in
                    //convert to engine and full file path
                    let engine = self.engines[ext]
                    return engine.map { (engine:ViewEngineType) -> (ViewEngineType, String) in
                        (engine, file)
                    }
                }.map { (engine, file) in
                    do {
                        return Result(value: try engine.view(file))
                    } catch let e as ExpressError {
                        switch e {
                            case ExpressError.FileNotFound(let filename): return Result(error: AnyError(cause: ExpressError.NoSuchView(name: filename)))
                            default: return Result(error: AnyError(cause: e))
                        }
                    } catch let e {
                        return Result(error: AnyError(cause: e))
                    }
                }.getOrElse(Result(error: AnyError(cause: ExpressError.NoSuchView(name: viewName))))
            }
        }
    }
    
    func render(view:String, context:Any?) -> Future<AbstractActionType, AnyError> {
        return self.view(view).map(renderContext) { view in
            try view.render(context)
        }
    }
}