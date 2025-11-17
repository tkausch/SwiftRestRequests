//
// This File belongs to SwiftRestEssentials 
// Copyright © 2024 Thomas Kausch.
// All Rights Reserved.

import XCTest
import Foundation
@testable import SwiftRestRequests


import Logging


class AbstractRestApiCallerTests: XCTestCase {

    private static let loggingLock = NSLock()

    override class func setUp() {
        super.setUp()

        // ***********************************************************
        // IMPORTANT NOTE: You must run httpbin locally for testing!!!
        // docker run -p 80:80 kennethreitz/httpbin
        // ************************************************************
        
        // Synchronize access to global logger state
        loggingLock.lock()
        defer { loggingLock.unlock() }
        
        Logger.SwiftRestRequests.security.logLevel = .trace
        Logger.SwiftRestRequests.interceptor.logLevel = .trace
        Logger.SwiftRestRequests.apiCaller.logLevel = .trace

    }
}
