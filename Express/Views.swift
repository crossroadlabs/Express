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
import Future
import Result
import Boilerplate

public class Views {
    //TODO: move hardcode to config
    internal var views:Dictionary<String, ViewType> = Dictionary()
    internal var paths:Array<String> = ["./views"]
    internal var engines:Dictionary<String, ViewEngineType> = Dictionary()
    internal let viewContext = ExecutionContext.view
    internal let renderContext = ExecutionContext.render
    
    public var cache:Bool = false
    func cacheView(viewName:String, view:Future<ViewType>) -> Future<ViewType> {
        if cache {
            return view.settle(in: self.viewContext).onComplete { result in
                if let val = try? result.dematerialize() {
                    self.views[viewName] = val
                }
            }
        } else {
            return view
        }
    }
    
    public func register(_ path:String) {
        future(context: viewContext) { ()->Void in
            self.paths.append(path)
        }
    }
    
    public func register(_ view: ViewType, name:String) {
        future(context: viewContext) {
            self.views[name] = view
        }
    }
    
    public func register(_ view: NamedViewType) {
        register(view, name: view.name)
    }
    
    public func register(_ engine: ViewEngineType) {
        future(context: viewContext) {
            let exts = engine.extensions()
            for ext in exts {
                self.engines[ext] = engine
            }
        }
    }
    
    func view(viewName:String, resolver: @escaping (String)->Future<ViewType>) -> Future<ViewType> {
        return future(context: viewContext) {
            Result<ViewType?, AnyError>(value: self.views[viewName])
        }.flatMap { (view:ViewType?) -> Future<ViewType> in
            return view.map { view in
                Future<ViewType>(value: view)
            }.getOrElse {
                return self.cacheView(viewName: viewName, view: resolver(viewName))
            }
        }
    }
    
    func view(viewName:String) -> Future<ViewType> {
        return view(viewName: viewName) { viewName in
            
            return future(context: self.viewContext) { ()->Result<ViewType, AnyError> in
                let fileManager = FileManager.default
                let exts = self.engines.keys
                
                let combinedData = self.paths.map { path in
                    exts.map { ext in
                        (ext, path.bridge().appendingPathComponent(viewName) + "." + ext)
                    }
                }.joined()
                
                return combinedData.findFirst { (ext, file) -> Bool in
                    // get first found template (ext, file)
                    //TODO: (path as NSString).stringByAppendingPathComponent(view) reimplement
                    var isDir = ObjCBool(false)
                    return fileManager.fileExists(atPath: file, isDirectory: &isDir) && !isDir.boolValue
                }.flatMap { (ext, file) -> (ViewEngineType, String)? in
                    //convert to engine and full file path
                    let engine = self.engines[ext]
                    return engine.map { (engine:ViewEngineType) -> (ViewEngineType, String) in
                        (engine, file)
                    }
                }.map { (engine, file)  -> Result<ViewType, AnyError> in
                    do {
                        return Result(value: try engine.view(filePath: file))
                    } catch let e as ExpressError {
                        switch e {
                            case ExpressError.FileNotFound(let filename): return Result(error: AnyError(ExpressError.NoSuchView(name: filename)))
                            default: return Result(error: AnyError(e))
                        }
                    } catch let e {
                        return Result(error: AnyError(e))
                    }
                }.getOrElse(el: Result(error: AnyError(ExpressError.NoSuchView(name: viewName))))
                
                
                
            }
        }
    }
    
    public func render<Context>(view:String, context:Context?) -> Future<FlushableContentType> {
        return self.view(viewName: view).settle(in: viewContext).map { view in
            try view.render(context: context)
        }
    }
}
