//
// RestApiCallerTest.swift
//
// This File belongs to SwiftRestRequests
// Copyright © 2024 Thomas Kausch.
// All Rights Reserved.


import XCTest
@testable import SwiftRestRequests

import XCTest

struct HttpBinHeaders: Decodable {
    let accept: String
    
    enum CodingKeys: String, CodingKey {
        case accept = "Accept"
    }
}

final class RestApiCallerTests: XCTestCase {
    
    var apiCaller: RestApiCaller!
    
    override func setUp()  {
        guard let url = URL(string: "https://httpbin.org") else {
            XCTFail("Bad test server URL!")
            return
        }
        apiCaller = RestApiCaller(baseUrl: url)
    }
    
    func testAcceptHeaderIsSentInRequest() async throws {
        
        struct Headers: Decodable {
            let Accept: String
        }
        
        struct HttpHeadersResponse: Decodable {
            let headers: Headers
        }
        
        let (response, httpStatus) = try await apiCaller.get(HttpHeadersResponse.self, at: "headers")
        
        XCTAssertEqual(httpStatus, 200)
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
        
        XCTAssertEqual(httpStatus, 200)
        XCTAssertEqual(response?.url, "https://httpbin.org/get")
        XCTAssertEqual(response?.headers.accept, "application/json")
    }
    
    func testGetWithErrorStatus() async throws {
        do {
            let httpStatus = try await apiCaller.get(at: "status/404")
        } catch {
            switch error {
            case let RestError.failedRestCall(_, status, error):
                XCTAssertEqual(status, 404)
                XCTAssertNil(error)
            default:
                XCTFail("FailedRestCall error is expected")
            }
        }
        
    }
    
    func testGetWithoutDecodable() async throws {
        let  httpStatus = try await apiCaller.get(at: "status/204")
        XCTAssertEqual(httpStatus, 204)
    }
    
}

// MARK: - Testing POST HTTP Calls

extension RestApiCallerTests {
    
    func testPOSTWithDecodable() async throws {
        
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
        
        let (response, httpStatus) = try await apiCaller.post(request, at: "post", responseType: HttpBinResponse.self)
        
        XCTAssertEqual(httpStatus, 200)
        XCTAssertEqual(response?.json, request)
        
    }
    
    func testPOSTWithoutDecodable() async throws {
        struct HttpBinRequest: Codable {
            let key1: String
            let key2: Int
            let key3: Float
            let key4: Bool
            let key5: [Int]
        }
        
        let request = HttpBinRequest(key1: "Hello", key2: 1, key3: 2.0, key4: true, key5: [1,2,3,4,5])
        
        let successStatus = try await apiCaller.post(request, at: "status/204")
        
        XCTAssertEqual(204, successStatus)
    }
    
    
}
