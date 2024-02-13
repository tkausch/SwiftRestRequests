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


/// Errors related to the networking for the `RestCaller`
public enum RestError: Error {

    /// Indicates that the server responded using an unknown protocol.
    /// - parameter URLResponse: The response returned form the server.
    /// - parameter Data: The raw returned data from the server.
    case badResponse(URLResponse, Data)

    /// Indicates the server's response could not be deserialized using the given Deserializer.
    /// - parameter HTTPURLResponse: The HTTPURLResponse from the server
    /// - parameter Data: The raw returned data from the server
    /// - parameter Error: The original system error (like a DecodingError, etc) that caused the malformedResponse to trigger
    case malformedResponse(HTTPURLResponse, Data, Error)
    
    
    // Indicates the api call to server was not successful and optional contains an error json object.
    /// - parameter HTTPURLResponse: The HTTPURLResponse from the server
    /// - parameter Int: The returned HTTP error status
    /// - parameter Error: The returned json error object
    case failedRestCall(HTTPURLResponse, Int, Any?)
}
