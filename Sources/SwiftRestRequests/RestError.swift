//
// RestError.swift
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
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


/// Errors thrown when executing REST requests.
///
/// Every case carries additional context so that callers can decide whether to retry, surface the failure,
/// or attempt to recover (for example when a deserializer reports malformed data).
public enum RestError: Error {

    /// Indicates that the server responded using an unknown protocol.
    /// - Parameters:
    ///   - URLResponse: The response returned form the server.
    ///   - Data: The raw returned data from the server.
    case badResponse(URLResponse, Data)
    
    /// Indicates that the server responded with an unexpected MIME type.
    /// - Parameter String: The returned MIME type.
    case invalidMimeType(String?)
    
    /// Indicates that query parameters with key could not be encoded using percent encoding.
    case invalidQueryParameter

    /// Indicates the server's response could not be deserialized using the given Deserializer.
    /// - Parameters:
    ///   - HTTPURLResponse: The HTTPURLResponse from the server.
    ///   - Data: The raw returned data from the server.
    ///   - Error: The original system error (like a `DecodingError`) that triggered the failure.
    case malformedResponse(HTTPURLResponse, Data, any Error)
    
    /// Indicates the API call failed and optionally surfaces the parsed error payload.
    /// - Parameters:
    ///   - HTTPURLResponse: The HTTPURLResponse from the server.
    ///   - HTTPStatusCode: The returned HTTP status.
    ///   - error: The deserialized error payload, if available.
    case failedRestCall(HTTPURLResponse, HTTPStatusCode, error: (any Sendable)?)
    
    /// Indicates that the response contained an unexpected HTTP status code.
    ///
    /// Configure `RestOptions.expectedStatusCodes` to mark additional status codes as valid.
    /// - Parameter Int: The HTTP status returned from the server.
    case unexpectedHttpStatusCode(Int)
    
}
