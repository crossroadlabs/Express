//===--- MustacheViewEngine.swift -----------------------------------------===//
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
import Mustache

class MustacheView : ViewType {
    let template:Template
    
    init(template:Template) {
        self.template = template
    }
    
    func render(context:Any?) throws -> AbstractActionType {
        do {
            let box = Box(context as? MustacheBoxable)
            let render = try template.render(box)
            return Action<AnyContent>.ok(AnyContent(str:render, contentType: "text/html"))
        } catch let e as MustacheError {
            switch e.kind {
                //TODO: double check no such error can be found at this place
                //case MustacheError.Kind.TemplateNotFound: throw ExpressError.FileNotFound(filename: <#T##String#>)
                default: throw ExpressError.Render(description: e.description, line: e.lineNumber, cause: e)
            }
        }
    }
}

public class MustacheViewEngine : ViewEngineType {
    public init() {
    }
    
    public func extensions() -> Array<String> {
        return ["mustache"]
    }
    
    public func view(filePath:String) throws -> ViewType {
        do {
            let template = try Template(path: filePath)
            return MustacheView(template: template)
        } catch let e as MustacheError {
            switch e.kind {
                case MustacheError.Kind.TemplateNotFound: throw ExpressError.FileNotFound(filename: filePath)
                default: throw ExpressError.Render(description: e.description, line: e.lineNumber, cause: e)
            }
        }
    }
}