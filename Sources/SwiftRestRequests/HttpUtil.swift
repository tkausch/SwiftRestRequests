//
// HttpUtil.swift
//
// This File belongs to SwiftRestRequests
// Copyright © 2024 Thomas Kausch.
// All Rights Reserved.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.

// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

import Foundation


/// Supported HTTP methods to exectue  REST requests
internal enum RestMethod: String {
    case Post = "POST"
    case Patch = "PATCH"
    case Get = "GET"
    case Put = "PUT"
    case Delete = "DELETE"
    
}

internal enum MimeType: String {
    case ApplicationJson =  "application/json"
    case TextPlain = "text/plain"
    case ApplicationOctetStream = "application/octet-stream"
    case ApplicationProblemJson = "application/problem+json"
    case Void = "*/*"
}

internal enum HttpHeaders: String {
    case ContentType = "Content-Type"
    case Accept = "Accept"
}
