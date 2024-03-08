//
// RestOptions.swift
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


/// Options for `RestController` calls. Allows you to set an expected HTTP status code, HTTP Headers, or to modify the request timeout.
public struct RestOptions {

    /// An optional set of HTTP Headers to send with the call.
    public var httpHeaders: [String : String]?

    /// The amount of time in `seconds` until the request times out.
    public var requestTimeoutSeconds = 60 as TimeInterval
    
    /// An optional set of query parameters to send with the call.
    public var queryParameters: [String: String]?
    
    /// The http status codes the service is expecting to throw. Default is nil - all status codes allwed. 
    /// Note: If services returns another HTTP status code this will triggger an error during the call.
    public var expectedStatusCodes: [Int]? 
    
    public init() {}
}
