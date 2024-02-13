//
//  File.swift
//  
//
//  Created by Thomas Kausch on 06.02.2024.
//

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
    case Json =  "application/json"
    case OctetStream = "application/octet-stream"
    case ProblemJson = "application/problem+json"
    case Void = "*/*"
}

internal enum HttpHeaders: String {
    case ContentType = "Content-Type"
    case Accept = "Accept"
}
