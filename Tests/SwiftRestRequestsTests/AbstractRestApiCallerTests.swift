//
// This File belongs to SwiftRestEssentials 
// Copyright © 2024 Thomas Kausch.
// All Rights Reserved.

import XCTest
import Foundation
@testable import SwiftRestRequests


import Logging


class AbstractRestApiCallerTests: XCTestCase {

    var url: URL!

    private static let loggingLock = NSLock()

    
    override func setUp() {
        super.setUp()       

        guard let url = URL(string: "http://localhost:80") else {
            XCTFail("Bad test server URL!")
            return
        }   
        self.url = url

        // ***********************************************************
        // IMPORTANT NOTE: You must run httpbin locally for testing!!!
        // docker run -p 80:80 kennethreitz/httpbin
        // ************************************************************
        
        // Synchronize access to global logger state
        Self.loggingLock.lock()
        defer { Self.loggingLock.unlock() }
        
        Logger.SwiftRestRequests.security.logLevel = .trace
        Logger.SwiftRestRequests.interceptor.logLevel = .trace
        Logger.SwiftRestRequests.apiCaller.logLevel = .trace

    }
}
