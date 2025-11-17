//
// AbstractRestApiCallerTests.swift
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
