//===--- AnyContent+JSON.swift --------------------------------------------===//
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
import TidyJSON

public extension AnyContent {
    func asJSON() -> JSON? {
        for ct in contentType {
            //TODO: move to constants
            if "application/json" == ct {
                do {
                    guard let text = self.asText() else {
                        return nil
                    }
                    let json = try JSON.parse(text)
                    return json
                } catch let e as TidyJSON.ParseError {
                    print(e)
                    return nil
                } catch let e {
                    print(e)
                    return nil
                }
            }
        }
        return nil
    }
}