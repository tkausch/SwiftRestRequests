//
// RestApiCallerSecurityTests.swift
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
@testable import SwiftRestRequests





final class RestApiCallerSecurityTests: AbstractRestApiCallerTests {
    
    var url: URL!
    
    let BearerToken = "ThisIsAVeryLongBearerToken"
    let BearerToken2 = "ThisIsAnotherVeryLongBearerToken"
    
    let User = "User"
    let Password = "Password"
    
    override func setUp()  {
        super.setUp()
        guard let url = URL(string: "https://httpbin.org") else {
            XCTFail("Bad test server URL!")
            return
        }
        self.url = url
    }
    
    func testBearerAuthorization() async throws {
        
        struct HttpBinBearerResponse: Decodable {
            let authenticated: Bool
            let token: String
        }
        
        let authorizer = BearerReqeustAuthorizer(token: BearerToken)
        let caller = RestApiCaller(baseUrl: url, authorizer: authorizer, enableNetworkTrace: true)
        
        var (response, httpStatus) = try await caller.get(HttpBinBearerResponse.self, at: "bearer")
        
        XCTAssertEqual(httpStatus, .ok)
        XCTAssertNotNil(response)
        XCTAssertTrue(response!.authenticated)
        XCTAssertEqual(response!.token, BearerToken)
        
        // NOW change bearer token
        
        authorizer.token = BearerToken2
        
        
        (response, httpStatus) = try await caller.get(HttpBinBearerResponse.self, at: "bearer")
        
        XCTAssertEqual(httpStatus, .ok)
        XCTAssertNotNil(response)
        XCTAssertTrue(response!.authenticated)
        XCTAssertEqual(response!.token, BearerToken2)
        
        
    }
    
   
    func testBasicAuthorization() async throws {
        
        struct HttpBinBasicResponse: Decodable {
            let authenticated: Bool
            let user: String
        }
        
        let basicAuthorizer = BasicRequestAuthorizer(username: User, password: Password)
        let caller = RestApiCaller(baseUrl: url, authorizer: basicAuthorizer, enableNetworkTrace: true)
        
        let (response, httpStatus) = try await caller.get(HttpBinBasicResponse.self, at: "basic-auth/\(User)/\(Password)")
        
        XCTAssertEqual(httpStatus, .ok)
        XCTAssertNotNil(response)
        XCTAssertTrue(response!.authenticated)
        XCTAssertEqual(response!.user, User)
    }
    
 
    
}
