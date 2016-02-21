//===--- StencilViewEngine.swift -----------------------------------------===//
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
import PathKit
import Stencil

private extension Path {
    var containerDir: Path {
        return Path(NSString(string: String(self)).stringByDeletingLastPathComponent)
    }
}

typealias StencilEdible = [String: Any]

private protocol StencilCookable {
    func cook() -> StencilEdible
}

extension Dictionary : StencilCookable {
    func cook() -> StencilEdible {
        return self.map { (k,v) in
            (String(k), v)
        }
    }
}

private let loaderKey = "loader"

class StencilView : ViewType {
    let template:Template
    let loader:TemplateLoader?
    
    init(template:Template, loader:TemplateLoader? = nil) {
        self.template = template
        self.loader = loader
    }
    
    func render(context:Any?) throws -> AbstractActionType {
        do {
            let edibleOption = context.flatMap{$0 as? StencilCookable }?.cook()
            let contextSupplied:[String:Any] = edibleOption.getOrElse(Dictionary())
            
            let loader = contextSupplied.findFirst { (k, v) in
                k == loaderKey
            }.map{$1}
            
            if let loader = loader {
                guard let loader = loader as? TemplateLoader else {
                    throw ExpressError.Render(description: "'loader' is a reserved key and can be of TemplateLoader type only", line: nil, cause: nil)
                }
                print("OK, loader: ", loader)
                //TODO: merge loaders
            }
            
            let contextLoader:[String:Any] = self.loader.map{["loader": $0]}.getOrElse(Dictionary())
            let finalContext = contextSupplied ++ contextLoader
            
            let stencilContext = Context(dictionary: finalContext)
            let render = try template.render(stencilContext)
            return Action<AnyContent>.ok(AnyContent(str:render, contentType: "text/html"))
        } catch let e as TemplateSyntaxError {
            throw ExpressError.Render(description: e.description, line: nil, cause: e)
        }
    }
}

public class StencilViewEngine : ViewEngineType {
    public init() {
    }
    
    public func extensions() -> Array<String> {
        return ["stencil"]
    }
    
    public func view(filePath:String) throws -> ViewType {
        do {
            let path = Path(filePath)
            let dir = path.containerDir
            let loader = TemplateLoader(paths: [dir])
            let template = try Template(path: path)
            return StencilView(template: template, loader: loader)
        } catch let e as TemplateSyntaxError {
            throw ExpressError.Render(description: e.description, line: nil, cause: e)
        }
    }
}
