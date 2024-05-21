//
// RestApiCallerTests.swift
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

import XCTest

struct HttpBinHeaders: Decodable {
    let accept: String
    
    enum CodingKeys: String, CodingKey {
        case accept = "Accept"
    }
}

final class RestApiCallerTests: AbstractRestApiCallerTests {
    
    var apiCaller: RestApiCaller!
    
    override func setUp()  {
        guard let url = URL(string: "https://httpbin.org") else {
            XCTFail("Bad test server URL!")
            return
        }
        apiCaller = RestApiCaller(baseUrl: url, enableNetworkTrace: true)
    }
    
    func testAcceptHeaderIsSentInRequest() async throws {
        
        struct Headers: Decodable {
            let Accept: String
        }
        
        struct HttpHeadersResponse: Decodable {
            let headers: Headers
        }
        
        let (response, httpStatus) = try await apiCaller.get(HttpHeadersResponse.self, at: "headers")
        
        XCTAssertEqual(httpStatus, .ok)
        XCTAssertNotNil(response)
        XCTAssertEqual(response!.headers.Accept, MimeType.ApplicationJson.rawValue)
    }
    
    
    
}

// MARK: - Testing GET HTTP Calls

extension RestApiCallerTests {
    
    
    func testGetWithDecodable() async throws {
        struct HttpBinResponse: Decodable {
            let url: String
            let origin: String
            let headers: HttpBinHeaders
        }
        
        let (response, httpStatus) = try await apiCaller.get(HttpBinResponse.self, at: "get")
        
        XCTAssertEqual(httpStatus, .ok)
        XCTAssertEqual(response?.url, "https://httpbin.org/get")
        XCTAssertEqual(response?.headers.accept, "application/json")
    }
    
    
    func testGetWithError() async throws {
        struct HttpBinResponse: Decodable {
            let url: String
            let origin: String
            let headers: HttpBinHeaders
        }
        
        do {
            let (_, _) = try await apiCaller.get(HttpBinResponse.self, at: "status/404")
            XCTFail("Above call must throw error")
        } catch RestError.failedRestCall(let httpResponse, let httpStatus, _) {
            XCTAssertEqual(httpStatus, .notFound)
            XCTAssertEqual(httpResponse.status, .notFound)
        } catch {
            XCTFail("RestError.failedRestCall error expected")
        }
        
    }
    
    
    func testGetErrorStatus() async throws {
        do {
            let status = try await apiCaller.get(at: "status/404")
        } catch RestError.failedRestCall(let response, let statusCode, _ ){
            XCTAssertEqual(statusCode, .notFound)
        }
    }
    
    func testGetOkStatus() async throws {
        let  status = try await apiCaller.get(at: "status/204")
        XCTAssertEqual(status, .noContent)
    }
    
}

// MARK: - Testing POST HTTP Calls

extension RestApiCallerTests {
    
    private func makePostOrPutCallWithEncodable(_ method: HTTPMethod) async throws {
        
        struct HttpBinRequest: Codable, Equatable {
            let key1: String
            let key2: Int
            let key3: Float
            let key4: Bool
            let key5: [Int]
        }
        
        struct HttpBinResponse: Decodable {
            let url: String
            let origin: String
            let headers: HttpBinHeaders
            let json: HttpBinRequest
        }
        
        let request = HttpBinRequest(key1: "Hello", key2: 1, key3: 2.0, key4: true, key5: [1,2,3,4,5])
       
        var result: (response: HttpBinResponse?, httpStatus: HTTPStatusCode)
        
        if method == .post {
            result = try await apiCaller.post(request, at: "post", responseType: HttpBinResponse.self)
        } else  {
            // Postcondition: method == PUT
            result = try await apiCaller.put(request, at: "put", responseType: HttpBinResponse.self)
        }
        
        XCTAssertEqual(result.httpStatus, .ok)
        XCTAssertEqual(result.response?.json, request)
    }
    
    private func makePostOrPutCallWithoutDecodable(_ method: HTTPMethod) async throws {
        struct HttpBinRequest: Codable {
            let key1: String
            let key2: Int
            let key3: Float
            let key4: Bool
            let key5: [Int]
        }
        
        let request = HttpBinRequest(key1: "Hello", key2: 1, key3: 2.0, key4: true, key5: [1,2,3,4,5])
        
        var status: HTTPStatusCode
        
        if method == .post {
           status = try await apiCaller.post(request, at: "status/204")
        } else {
            // Postcondition: method == PUT
            status = try await apiCaller.put(request, at: "status/204")
        }
        
        XCTAssertEqual(status, .noContent)
    }
    
    func testPostWithDecodable() async throws {
        try await makePostOrPutCallWithEncodable(.post)
    }

    func testPutWithDecodable() async throws {
        try await makePostOrPutCallWithEncodable(.put)
    }
    
    func testPostWithoutDecodable() async throws {
        try await makePostOrPutCallWithoutDecodable(.post)
    }
    
    func testPutWithoutDecodable() async throws {
        try await makePostOrPutCallWithoutDecodable(.put)
    }
    
}

// MARK: - Check services are only returning expected status codes

extension RestApiCallerTests {
    
    func testExpectedStatusCodeReturned() async throws {
        var options = RestOptions()
        
        // define common status codes expected
        let expectedStatusCodes: [HTTPStatusCode] = [.internalServerError, .ok, .noContent, .forbidden, .noContent]
        options.expectedStatusCodes = expectedStatusCodes

        for statusCode in expectedStatusCodes {
            do {
                let returnedStatus =  try await apiCaller.get(at: "status/\(statusCode.rawValue)", options: options)
                XCTAssertEqual(statusCode, returnedStatus)
            } catch RestError.failedRestCall(let response, let errorStatus, _ ) {
                XCTAssertEqual(statusCode, errorStatus)
            }
        }
    }
    
    func testExpectedStatusCodeNotReturned() async throws {
        var options = RestOptions()
        
        // define common status codes expected
        let expectedStatusCodes: [HTTPStatusCode] = [.internalServerError, .ok, .noContent, .forbidden]
        options.expectedStatusCodes = expectedStatusCodes
        
        do {
            let _ = try await apiCaller.get(at: "status/501", options: options)
            XCTFail("Above call should throw errror")
        } catch RestError.unexpectedHttpStatusCode(let statusCode) {
            XCTAssertEqual(501, statusCode)
        }
    }
    
}


// MARK: - URL Parameter encoding tests


extension RestApiCallerTests {
    
    func testURLEncoding() async throws {
     
        struct HttpBinGetArgsRequest: Codable {
            let args: [String: String]
            let url: String
        }
        
        var options = RestOptions()
        
        let params: [String: String] = ["param1": "DiesisteinTest", "params2": "1.0", "params3": "&%#"]
        options.queryParameters = params
        
        do {
            let (response, status) = try await apiCaller.get(HttpBinGetArgsRequest.self, at: "get",options: options)
            
            XCTAssertEqual(status, .ok)
            XCTAssertNotNil(response?.args)
            
            if let receivedArgs = response?.args {
                // validate params are mirrored correctly...
                for key in params.keys {
                    XCTAssertEqual(params[key], receivedArgs[key])
                }
            }
            
        } catch {
            XCTAssertNil(error)
        }
        
    }
    
    
}
