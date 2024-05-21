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

import Logging

open class LogNetworkInterceptor: URLRequestInterceptor {
    
    static let noBody =  "none"
    
    public func invokeRequest(request: inout URLRequest, for session: URLSession) {
        
        guard let requestHeaders = request.allHTTPHeaderFields,
              let headerData = try? JSONSerialization.data(withJSONObject: requestHeaders , options: .prettyPrinted),
              let prettyJsonHeaders = String(data: headerData , encoding: .utf8) else {
            Logger.interceptorLogger.warning("Something went wrong while converting headers to JSON data.")
            return
        }
        
        let prettyJsonBody = request.httpBody?.prettyPrintedJSONString ?? "nil"
        
        let url = request.url?.absoluteString ?? "nil"
        let method = request.httpMethod ?? "nil"
        
        Logger.interceptorLogger.info("Will invoke request: \(method) \(url)")
        
        Logger.interceptorLogger.trace("HTTP request headers: \(prettyJsonHeaders)")
        Logger.interceptorLogger.trace("HTTP request body: \(prettyJsonBody)")
    }
    
    public func receiveResponse(data:  Data, response: HTTPURLResponse, for session: URLSession) {

        guard let headerData = try? JSONSerialization.data(withJSONObject:  response.allHeaderFields, options: .prettyPrinted),
              let prettyJsonHeaders = String(data: headerData , encoding: .utf8) else {
            print("WARNING: Something went wrong while converting headers to JSON data.")
            return
        }
        
        
        let prettyJsonBody = data.prettyPrintedJSONString ?? "nil"
        
        let url = response.url?.absoluteString ?? "nil"
        let status = response.statusCode

        
        Logger.interceptorLogger.info("Did receive response: \(url) ->  \(status)")
        
        Logger.interceptorLogger.trace("HTTP response headers: \(prettyJsonHeaders)")
        Logger.interceptorLogger.trace("HTTP response body: \(prettyJsonBody)")
    }
}

extension Data {
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



