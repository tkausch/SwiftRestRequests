//
//  File.swift
//  
//
//  Created by Thomas Kausch on 06.02.2024.
//

import Foundation


/// Options for `RestController` calls. Allows you to set an expected HTTP status code, HTTP Headers, or to modify the request timeout.
public struct RestOptions {

    /// An optional set of HTTP Headers to send with the call.
    public var httpHeaders: [String : String]?

    /// The amount of time in `seconds` until the request times out.
    public var requestTimeoutSeconds = 60 as TimeInterval
    
    /// An optional set of query parameters to send with the call.
    public var queryParameters: [String: String]?
    
    public init() {}
}
