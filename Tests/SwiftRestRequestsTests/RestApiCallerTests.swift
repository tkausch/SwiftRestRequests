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
            XCTAssertEqual(httpStatus, 404)
            XCTAssertEqual(httpResponse.statusCode, 404)
        } catch {
            XCTFail("RestError.failedRestCall error expected")
        }
        
    }
    
    
    func testGetErrorStatus() async throws {
        let status = try await apiCaller.get(at: "status/404")
        XCTAssertEqual(status, 404)
    }
    
    func testGetOkStatus() async throws {
        let  httpStatus = try await apiCaller.get(at: "status/204")
        XCTAssertEqual(httpStatus, 204)
    }
    
}

// MARK: - Testing POST HTTP Calls

extension RestApiCallerTests {
    
    private func makePostOrPutCallWithEncodable(_ method: RestMethod) async throws {
        
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
       
        var result: (response: HttpBinResponse?, httpStatus: Int)
        
        if method == .Post {
            result = try await apiCaller.post(request, at: "post", responseType: HttpBinResponse.self)
        } else  {
            // Postcondition: method == PUT
            result = try await apiCaller.put(request, at: "put", responseType: HttpBinResponse.self)
        }
        
        XCTAssertEqual(result.httpStatus, 200)
        XCTAssertEqual(result.response?.json, request)
    }
    
    private func makePostOrPutCallWithoutDecodable(_ method: RestMethod) async throws {
        struct HttpBinRequest: Codable {
            let key1: String
            let key2: Int
            let key3: Float
            let key4: Bool
            let key5: [Int]
        }
        
        let request = HttpBinRequest(key1: "Hello", key2: 1, key3: 2.0, key4: true, key5: [1,2,3,4,5])
        
        var successStatus: Int
        
        if method == .Post {
           successStatus = try await apiCaller.post(request, at: "status/204")
        } else {
            // Postcondition: method == PUT
            successStatus = try await apiCaller.put(request, at: "status/204")
        }
        
        XCTAssertEqual(204, successStatus)
    }
    
    func testPostWithDecodable() async throws {
        try await makePostOrPutCallWithEncodable(.Post)
    }

    func testPutWithDecodable() async throws {
        try await makePostOrPutCallWithEncodable(.Put)
    }
    
    func testPostWithoutDecodable() async throws {
        try await makePostOrPutCallWithoutDecodable(.Post)
    }
    
    func testPutWithoutDecodable() async throws {
        try await makePostOrPutCallWithoutDecodable(.Put)
    }
    
}
