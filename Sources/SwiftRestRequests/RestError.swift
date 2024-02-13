//
//  File.swift
//  
//
//  Created by Thomas Kausch on 06.02.2024.
//

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
