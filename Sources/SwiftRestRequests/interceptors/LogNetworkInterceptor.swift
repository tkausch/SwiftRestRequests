//
// LogNetworkInterceptor.swift
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


import Logging

/// Interceptor that logs outgoing requests and incoming responses using `swift-log`.
open class LogNetworkInterceptor: URLRequestInterceptor, @unchecked Sendable {
    
    static let noBody =  "none"
    
    let logger = Logger.SwiftRestRequests.interceptor
    let enableNetworkTracing: Bool
    
    
    /// Creates a new interceptor.
    /// - Parameter enableNetworkTracing: When `true`, headers, cookies, and bodies are pretty-printed; otherwise only method/URL pairs are logged.
    public init(enableNetworkTracing: Bool) {
        self.enableNetworkTracing = enableNetworkTracing
    }
    
    private func prettyCookieHeaders(_ cookieList: [HTTPCookie]) -> String {
        return cookieList.reduce("") { partialResult, cookie in
            partialResult + "  \"\(cookie.name)\": \"\(cookie.value)\"\n "
        }
    }
    
    /// Logs request metadata before the request is executed.
    public func invokeRequest(request: inout URLRequest, for session: URLSession) {
        
        guard let requestHeaders = request.allHTTPHeaderFields,
              let headerData = try? JSONSerialization.data(withJSONObject: requestHeaders , options: .prettyPrinted),
              let prettyJsonHeaders = String(data: headerData , encoding: .utf8) else {
            logger.warning("Something went wrong while converting headers to JSON data.")
            return
        }
        
        let prettyJsonBody = request.httpBody?.prettyPrintedJSONString ?? "nil"
        
        let url = request.url?.absoluteString ?? "nil"
        let method = request.httpMethod ?? "nil"
        
        if enableNetworkTracing {
            var prettyCookies = ""
            if let requestUrl = request.url, let cookieList =  session.configuration.httpCookieStorage?.cookies(for: requestUrl) {
                prettyCookies = prettyCookieHeaders(cookieList)
            }
            logger.info("Request: \(method) \(url)\nheaders: \(prettyJsonHeaders) \ncookieHeaders: { \n\(prettyCookies)} \nbody: \(prettyJsonBody)")
        } else {
            logger.info("Request: \(method) \(url)")
        }
        
       
    }
    
    /// Logs response metadata once the request finishes.
    public func receiveResponse(data:  Data, response: HTTPURLResponse, for session: URLSession) {

        guard let headerData = try? JSONSerialization.data(withJSONObject:  response.allHeaderFields, options: .prettyPrinted),
              let prettyJsonHeaders = String(data: headerData , encoding: .utf8) else {
            print("WARNING: Something went wrong while converting headers to JSON data.")
            return
        }
        
        
        let prettyJsonBody = data.prettyPrintedJSONString ?? "nil"
        
        let url = response.url?.absoluteString ?? "nil"
        let status = response.statusCode
        
        
        if enableNetworkTracing {
            logger.info("Response: \(url) -> \(status)\nheaders: \(prettyJsonHeaders) \nbody: \(prettyJsonBody)")
        } else {
            logger.info("Response: \(url) -> \(status)")
        }
        
    }
}

extension Data {
    /// Pretty-prints the data when it represents JSON; falls back to `debugDescription` otherwise.
    var prettyPrintedJSONString: String? { /// NSString gives us a nice sanitized debugDescription
        
        guard self.count > 0 else {
            return nil
        }
        
        guard let object = try? JSONSerialization.jsonObject(with: self, options: [.fragmentsAllowed]),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else {
            return self.debugDescription
        }
        return prettyPrintedString
    }
}

