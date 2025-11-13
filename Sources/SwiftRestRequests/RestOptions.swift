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


/// Customisation options that apply to a single REST invocation.
///
/// Use `RestOptions` to override headers, query parameters, expected status codes, or the timeout without
/// mutating the base `RestApiCaller` configuration.
public struct RestOptions {

    /// An optional set of HTTP Headers to send with the call.
    public var httpHeaders: [String : String]?

    /// The amount of time in `seconds` until the request times out.
    public var requestTimeoutSeconds = 60 as TimeInterval
    
    /// An optional set of query parameters to send with the call.
    public var queryParameters: [String: String]?
    
    /// HTTP status codes that should be treated as success for the request. When `nil` every
    /// code accepted by the underlying deserializer is treated as success.
    ///
    /// Any response outside of this set triggers a `RestError.unexpectedHttpStatusCode`.
    public var expectedStatusCodes: [HTTPStatusCode]?
    
    /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    public var dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.iso8601
    
    /// Creates a new instance with default timeout and without overrides.
    public init() {}
}
