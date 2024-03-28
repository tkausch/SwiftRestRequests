//
// This File belongs to SwiftRestEssentials 
// Copyright © 2024 Thomas Kausch.
// All Rights Reserved.


import Foundation

#if os(Linux)
// no network tracing is implemented
#else

import os

public class TraceNetworkInterceptor: URLRequestInterceptor {
    
    let logger: Logger
    
    init() {
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: "SwidtRestReqeusts")
    }
    
    public func invokeRequest(request: inout URLRequest, for session: URLSession) {
        
        guard let requestHeaders = request.allHTTPHeaderFields,
              let headerData = try? JSONSerialization.data(withJSONObject: requestHeaders , options: .prettyPrinted),
              let prettyJsonHeaders = String(data: headerData , encoding: .utf8) else {
            print("WARNING: Something went wrong while converting headers to JSON data.")
            return
        }
        
        let prettyJsonBody = request.httpBody?.prettyPrintedJSONString ?? "no body"
        
        let url = request.url?.absoluteString ?? "nil"
        let method = request.httpMethod ?? "nil"
        
        logger.trace("Invoke: \(method) \(url) \n\(prettyJsonHeaders) \n\(prettyJsonBody)")
    }
    
    public func receiveResponse(data:  Data, response: HTTPURLResponse, for session: URLSession) {

        guard let headerData = try? JSONSerialization.data(withJSONObject:  response.allHeaderFields, options: .prettyPrinted),
              let prettyJsonHeaders = String(data: headerData , encoding: .utf8) else {
            print("WARNING: Something went wrong while converting headers to JSON data.")
            return
        }
        
        
        let prettyJsonBody = data.prettyPrintedJSONString
        
        let url = response.url?.absoluteString ?? "nil"
        let status = response.statusCode
        
        logger.trace("Received: \(url) ->  \(status) \n\(prettyJsonHeaders) \n\(prettyJsonBody)")
    }
}

#endif

extension Data {
    var prettyPrintedJSONString: String { /// NSString gives us a nice sanitized debugDescription
        
        guard self.count > 0 else {
            return "body empty"
        }
        
        guard let object = try? JSONSerialization.jsonObject(with: self, options: [.fragmentsAllowed]),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else {
            return self.debugDescription
        }
        return prettyPrintedString
    }
}
