//
// This File belongs to SwiftRestEssentials 
// Copyright © 2024 Thomas Kausch.
// All Rights Reserved.

import XCTest
@testable import SwiftRestRequests


import Logging


class AbstractRestApiCallerTests: XCTestCase {

    // When available we prefere to use the OSLog
    static var onceExecution: () = {
        
        #if os(Linux)
           // Configure `swift-log`default logger
        #else
            /// Configure `swift-log` logging system to use OSLog backend
            LoggingSystem.bootstrap(OSLogHandler.init)
        #endif
        
        Logger.SwiftRestRequests.security.logLevel = .trace
        Logger.SwiftRestRequests.interceptor.logLevel = .trace
        Logger.SwiftRestRequests.apiCaller.logLevel = .trace
        
    }()
    
    
    override func setUp()  {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let _ = AbstractRestApiCallerTests.onceExecution
        
    }

}
