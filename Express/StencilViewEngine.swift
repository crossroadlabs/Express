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

class StencilView : ViewType {
    let template:Template
    
    init(template:Template) {
        self.template = template
    }
    
    func render(context:Any?) throws -> AbstractActionType {
        do {
            let edibleOption = context.flatMap{$0 as? StencilCookable }?.cook()
            guard let edible = edibleOption else {
                throw ExpressError.Render(description: "Unable to render supplied context", line: nil, cause: nil)
            }
            
            let stencilContext = Context(dictionary: edible)
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
            let template = try Template(path: path)
            return StencilView(template: template)
        } catch let e as TemplateSyntaxError {
            throw ExpressError.Render(description: e.description, line: nil, cause: e)
        }
    }
}
