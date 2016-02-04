//===--- JsonView.swift ---------------------------------------------------===//
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
import SwiftyJSON

public class JsonView : NamedViewType {
    public let name:String = "json"
    
    public init() {
    }
    
    public func render(context:AnyObject?) throws -> AbstractActionType {
        //TODO: implement reflection
        let json = context.map { context in
            JSON(context)
        }.getOrElse(JSON(Dictionary()))
        //TODO: avoid string path
        guard let render = json.rawString() else {
            throw ExpressError.Render(description: "unable to render json: " + (context?.description).getOrElse("None"), line: nil, cause: nil)
        }
        return Action<AnyContent>.ok(AnyContent(str:render, contentType: "application/json"))
    }
}