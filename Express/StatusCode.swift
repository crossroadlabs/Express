//===--- StatusCode.swift -------------------------------------------------===//
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

public enum StatusCode : UInt16 {
    case Accepted = 202
    case BadRequest = 400
    case Conflict = 409
    case Created = 201
    case EntityTooLarge = 413
    case ExpectationFailed = 417
    case Forbidden = 403
    case Found = 302
    case Gone = 410
    case InternalServerError = 500
    case MethodNotAllowed = 405
    case MovedPermanently = 301
    case NoContent = 204
    case NonAuthoritativeInformation = 203
    case NotAcceptable = 406
    case NotFound = 404
    case NotImplemented = 501
    case NotModified = 304
    case Ok = 200
    case PartialContent = 206
    case PreconditionFailed = 412
    case RequestTimeout = 408
    case ResetContent = 205
    case SeeOther = 303
    case ServiceUnavailable = 503
    case TemporaryRedirect = 307
    case TooManyRequest = 429
    case Unauthorized = 401
    case UnsupportedMediaType = 415
    case UnavailableForLegalReasons = 451 //farenheit
    case UriTooLong = 414
}

public enum RedirectStatusCode : UInt16 {
    case MovedPermanently = 301
    case Found = 302
    case SeeOther = 303
    case TemporaryRedirect = 307
}