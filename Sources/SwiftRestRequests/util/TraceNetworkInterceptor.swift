//
// This File belongs to SwiftRestEssentials 
// Copyright © 2024 Thomas Kausch.
// All Rights Reserved.


import Foundation
import os

public class TraceNetworkInterceptor: URLRequestInterceptor {
    
    let logger: Logger
    
    init() {
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: "SwidtRestReqeusts")
    }
    
    public func invokeRequest(request: inout URLRequest, for session: URLSession) {
        let requestDebugDescription = request.debugDescription
        let prettyJsonBody = request.httpBody?.prettyPrintedJSONString ?? "Body contains no data!"
        
        let url = request.url?.absoluteString ?? "nil"
        let method = request.httpMethod ?? "nil"
        
        logger.trace("Invoke: \(method) \(url) \n\(requestDebugDescription) \n\(prettyJsonBody)")
    }
    
    public func receiveResponse(data:  Data, response: HTTPURLResponse, for session: URLSession) {
        let responseDebugDescription = response.debugDescription
        let prettyJsonBody = data.prettyPrintedJSONString
        
        let url = response.url?.absoluteString ?? "nil"
        let status = response.statusCode
        
        logger.trace("Received: \(url) ->  \(status) \n\(responseDebugDescription) \n\(prettyJsonBody)")
    }
}

extension Data {
    var prettyPrintedJSONString: String { /// NSString gives us a nice sanitized debugDescription
        
        guard self.count > 0 else {
            return "Body contains no data!"
        }
        
        guard let object = try? JSONSerialization.jsonObject(with: self, options: [.fragmentsAllowed]),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else {
            return self.debugDescription
        }
        return prettyPrintedString
    }
}
