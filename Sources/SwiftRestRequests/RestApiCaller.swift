//
// RestApiCaller.swift
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

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Logging


// MARK: - Protocols used by RestapiCaller

/// Allows users to generate headers before each REST call is made. The headers returned will be COMBINED with
/// any headers set in the original `RestCaller` call. Any headers returned here will override the values given
/// in the original call if they have the same name.
///
/// - parameter requestUrl: The URL that this header generation request is for. Never nu,,
public typealias HeaderGenerator = (URL) -> [String : String]?

/// A request interceptor is used to intercept  REST requests and responses. It can be used to change underlying HTTP  requests or responses.
public protocol URLRequestInterceptor: AnyObject {
    func invokeRequest(request: inout URLRequest, for session: URLSession);
    func receiveResponse(data: Data, response: HTTPURLResponse, for session: URLSession);
}

extension URLRequestInterceptor {
    public func receiveResponse(data: Data, response: HTTPURLResponse, for session: URLSession) {
        // default empty implementation for optional method
    }
}

// MARK: - The Main class

/// Allows users to create HTTP REST networking calls that deal with JSON.
///
/// **NOTE:** Ensure to configure `App Transport Security` appropriately.
open class RestApiCaller : NSObject {
    
    let logger = Logger.SwiftRestRequests.apiCaller

    let session: URLSession
    let baseUrl: URL
    let errorDeserializer: (any Deserializer)?
    let httpCookieStorage: HTTPCookieStorage?
    
    /// Contains an optional  array of request interceptors.
    var interceptors:  [URLRequestInterceptor]?
    
    /// This header generator closure will be called before the caller is invoking the HTTP request. The returned headers are inserted into the request before invoking it.
    public let headerGenerator: HeaderGenerator?
    
    public let authorizer: URLRequestAuthorizer?

// MARK: Lifecycle
    
    
    /// Convenience initializer to create new `RestApiCaller`instances. Each instance will  create it's own `URLSession` object using the porvided `URLSessionConfiguration`.
    /// - Parameters:
    ///   - baseUrl: The base URL to which requests are sent.
    ///   - sessionConfig: The session coniguration to be used
    ///   - errorDeserializer: An optional error deserializer that can be used to deserialize generic error JSON.
    public convenience init(baseUrl: URL, sessionConfig:  
                            URLSessionConfiguration = URLSessionConfiguration.default,
                            authorizer: URLRequestAuthorizer? = nil,
                            errorDeserializer: (any Deserializer)? = nil,
                            headerGenerator: HeaderGenerator? = nil,
                            enableNetworkTrace: Bool = false,
                            httpCookieStorage: HTTPCookieStorage? = nil) {
        
        if let httpCookieStorage {
            sessionConfig.httpCookieAcceptPolicy = .always
            sessionConfig.httpShouldSetCookies = true
            sessionConfig.httpCookieStorage = httpCookieStorage
        }
        
        self.init(baseUrl: baseUrl, urlSession: URLSession(configuration: sessionConfig), authorizer: authorizer, errorDeserializer: errorDeserializer, headerGenerator: nil, enableNetworkTrace: enableNetworkTrace, httpCookieStorage: httpCookieStorage)
    }

    
    ///  Creates a fully functional RestApi Caller with full flexiblilty to configure.
    /// - Parameters:
    ///   - baseUrl: The base URL to which requests are sent.
    ///   - urlSession: The session coniguration to be used. Note: You can fully configure this session i.e. using delegates.
    ///   - errorDeserializer: An optional error deserializer that can be used to deserialize generic error JSON.
    public init(baseUrl: URL, urlSession: URLSession, authorizer: URLRequestAuthorizer?, errorDeserializer: (any Deserializer)?, headerGenerator: HeaderGenerator?, enableNetworkTrace: Bool, httpCookieStorage: HTTPCookieStorage?) {
        self.baseUrl = baseUrl
        self.errorDeserializer = errorDeserializer
        self.session = urlSession
        self.headerGenerator = headerGenerator
        self.authorizer = authorizer
        self.httpCookieStorage = httpCookieStorage
        
        super.init()
        
        if let authorizer {
            registerRequestInterceptor(AuthorizerInterceptor(authorization: authorizer))
        }
        
        #if os(Linux)
            if enableNetworkTrace {
                print("WARNING: Networktracing is NOT supported on Linux!")
            }
        #else
            registerRequestInterceptor(LogNetworkInterceptor(enableNetworkTracing: enableNetworkTrace))
        #endif
     
        logger.info("Created RestApiCaller (baseUrl=\(baseUrl); enabledNetworkTrace=\(enableNetworkTrace))")
    }
    
// MARK: Generic request dispatching methods
    
    @inline(__always)
    private func callInvokeInterceptors(_ request: inout URLRequest) {
        if let interceptors {
            for interceptor in interceptors {
                interceptor.invokeRequest(request: &request, for: session)
            }
        }
    }
    @inline(__always)
    private func callReceiveInterceptors(_ data: Data, _ response: HTTPURLResponse) {
        if let interceptors {
            // we revers interceptor chain when receiving...
            for interceptor in interceptors.reversed() {
                interceptor.receiveResponse(data: data, response: response, for: session)
            }
        }
    }
    
    @inline(__always)
    private func addPercentEncodeQueryParamsToUrl(url restURL: inout URL, queryParams: [String: String]?) throws {
        if let queryParams {
            var queryItems = [URLQueryItem]()
            for (key, value) in queryParams {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            if var urlComponents = URLComponents(url: restURL, resolvingAgainstBaseURL: true) {
                urlComponents.queryItems = queryItems
                if let restURLWithQuery = urlComponents.url {
                    restURL = restURLWithQuery
                } else {
                    throw RestError.invalidQueryParameter
                }
            }
        }
    }
    
    @inline(__always)
    private func insertHttpHeadersToRequest(_ request: inout URLRequest, httpHeaders: [String : String]?, url restURL: URL) {
      
        request.setValue(MimeType.ApplicationJson.rawValue, forHTTPHeaderField: HTTPHeaderKeys.Accept.rawValue)
        if let customHeaders = httpHeaders {
            for (httpHeaderKey, httpHeaderValue) in customHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }
        
        // Append rest endpoint specific headers
        if let generatedHeaders = headerGenerator?(restURL) {
            for (httpHeaderKey, httpHeaderValue) in generatedHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }
    }
    
    @inline(__always)
    private func validateResponseStatusCodes(_ expectedStatusCodes: [HTTPStatusCode]?, _ httpResponse: HTTPURLResponse) throws {
        if let expectedStatusCodes, !expectedStatusCodes.contains(httpResponse.status) {
            throw RestError.unexpectedHttpStatusCode(httpResponse.statusCode)
        }
    }
    
    @inline(__always)
    private func addPayloadToRequest( _ request: inout URLRequest, payload: Data?) {
        if let payloadToSend = payload {
            request.setValue(MimeType.ApplicationJson.rawValue, forHTTPHeaderField: HTTPHeaderKeys.ContentType.rawValue)
            request.httpBody = payloadToSend
        }
    }
    
    /// Execute REST data task against specified server endpoint and return data and the corresponding `HTTPURLResponse` instance.
    /// - Parameters:
    ///   - relativePath: Relative pass for the REST endpoint.
    ///   - httpMethod: HTTP method to be used
    ///   - accept: The accepted content type we do expect
    ///   - payload: The JSON payload to be sent to server in binary format
    ///   - options: Rest options to use for the data task i.e. timeout
    /// - Returns: The data returned by server and the corresponding `HTTPURLResponse`
    private func dataTask(relativePath: String?, httpMethod: String, accept: String, payload: Data?, options: RestOptions) async throws -> (Data, HTTPURLResponse) {
        
        logger.debug("Data Task \(httpMethod) \(String(describing: relativePath)) started with timeout \(options.requestTimeoutSeconds) seconds.")
        
        var restURL: URL;
        if let relativeURL = relativePath {
            restURL = baseUrl.appendingPathComponent(relativeURL)
        } else {
            restURL = baseUrl
        }
    
        try addPercentEncodeQueryParamsToUrl(url: &restURL, queryParams: options.queryParameters)
        
        // Create URLRequest
        var request = URLRequest(url: restURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: options.requestTimeoutSeconds)
        request.httpMethod = httpMethod
        
        insertHttpHeadersToRequest(&request, httpHeaders: options.httpHeaders, url: restURL)

        addPayloadToRequest(&request, payload: payload)

        // make request and install interceptor hooks
        callInvokeInterceptors(&request)
        let (data, response) = try await session.data(for: request)
        
        
        // check http response has a supported type
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RestError.badResponse(response, data)
        }
        
        callReceiveInterceptors(data, httpResponse)
        
        try validateResponseStatusCodes(options.expectedStatusCodes, httpResponse)
        
        return (data, httpResponse)
    }
    
    /// Make a REST call and deserialize the response with the given deserializer from JSON to object. For successful calls the httpStatus is returned as well. Note:
    /// Some REST services do not always return
    /// - Parameters:
    ///   - relativePath: Relative pass for the REST endpoint
    ///   - httpMethod: HTTP method to be used
    ///   - accept: The accepted content type we do expect
    ///   - payload: The JSON payload to be sent to server in binary format
    ///   - options: Rest options to use for the data task i.e. timeout
    /// - Returns: The data returned by server and the corresponding `HTTPURLResponse`
    private func makeCall<T: Deserializer>(_ relativePath: String?, httpMethod: HTTPMethod, payload: Data?, responseDeserializer: T, options: RestOptions) async throws -> (T.ResponseType?, HTTPStatusCode) {
        
        let (data, httpResponse) = try await dataTask(relativePath: relativePath, httpMethod: httpMethod.rawValue, accept: responseDeserializer.acceptHeader, payload: payload, options: options)
       
        let httpStatus = httpResponse.status
        
        // For requests without deserialization and no error just return the status
        if type(of: responseDeserializer) == VoidDeserializer.self {
            if httpStatus.type == .success {
                return (nil, httpResponse.status)
            }
        }
        
        guard !data.isEmpty  else {
            throw RestError.failedRestCall(httpResponse, httpStatus, error: nil)
        }
        
        // Postcondition: We have a response object or  error that needs to be parsed!
        
        let contentType =  httpResponse.value(forHTTPHeaderField: HTTPHeaderKeys.ContentType.rawValue)
        
        // Note: some servers return also encoding i.e. Content-Type: application/json; charset=utf-8 take the first part
        let firstContentMimeType = contentType?.components(separatedBy: ";").first
        
        guard  let firstContentMimeType, let _ = MimeType(rawValue: firstContentMimeType) else {
            throw RestError.invalidMimeType(contentType)
        }
        
        // Postcondition: Response or error ContentTyp is supported
        
        if httpStatus.type == .success  {
            
            // Postcondition: httpStatus in 200...299
            if httpStatus == .ok {
                // Postcondition: httpStatus is 200 we need to deserialize
                do {
                    let transformedResponse = try responseDeserializer.deserialize(data)
                    return (transformedResponse, httpResponse.status)
                } catch {
                    throw RestError.malformedResponse(httpResponse, data, error)
                }
            } else {
                // Postcondition: httpStatus is 201...299
                // Note: we skipt data in this case
                return (nil, httpStatus)
            }
            
        } else {
            
            // Postcondition: httpStatus not 2XX. We have an error and error data
            var failedRestCallError: RestError
            
            do {
                let errorJson = try errorDeserializer?.deserialize(data)
                failedRestCallError =  RestError.failedRestCall(httpResponse, httpStatus, error: errorJson)
            } catch {
                throw RestError.malformedResponse(httpResponse, data, error)
            }
            
            throw failedRestCallError
            
        }
            
    }

    
    
// MARK: Public API that can be used from other classes or subclass
    
    /// Add request interceptor to the api caller.
    /// - Parameter interceptor: The interceptor to be called
    public func registerRequestInterceptor(_ interceptor: URLRequestInterceptor) {
        logger.info("Registering request interceptor: \(interceptor)")
        if  self.interceptors == nil {
            self.interceptors = [URLRequestInterceptor]()
        }
        interceptors!.append(interceptor)
    }
    
    /// Performs a GET request to the server, capturing the data object type response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter type: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` type of `D` object that was returned from the server or nil together with returned successful httpStatus.
    public func get<D: Decodable & Sendable>(_ type: D.Type, at relativePath: String?, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .get, payload: nil, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Performs a GET request to the server, capturing the data object type response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter type: The type of object this get call returns.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: The successful HTTP response status.
    public func get(at relativePath: String?, options: RestOptions = RestOptions()) async throws -> HTTPStatusCode {
        let decodableDeserializer = VoidDeserializer()
        let ( _ , httpStatus) = try await makeCall(relativePath, httpMethod: .get, payload: nil, responseDeserializer: decodableDeserializer, options: options)
        return httpStatus
    }

    /// Performs a POST request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server or nil together with returned successful httpStatus.
    public func post<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .post, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    
    /// Performs a POST request to the server without capturing response. Only successful httpStatus is returned!
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: The successful HTTP response status.
    public func post<E: Encodable>(_ encodable: E, at relativePath: String?, options: RestOptions = RestOptions()) async throws -> HTTPStatusCode {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = VoidDeserializer()
        let ( _ , httpStatus) = try await makeCall(relativePath, httpMethod: .post, payload: payload, responseDeserializer: decodableDeserializer, options: options)
        return httpStatus
    }
    
    
    
    /// Performs a PUT request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server or nil together with returned successful httpStatus.
    public func put<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .put, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Performs a PUT request to the server, capturing the HTTP response status.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: The successful HTTP response status.
    public func put<E: Encodable>(_ encodable: E, at relativePath: String?, options: RestOptions = RestOptions()) async throws ->  HTTPStatusCode {
        let payload = try JSONEncoder().encode(encodable)
        let voidDeserializer = VoidDeserializer()
        let (_, httpStatus) = try await makeCall(relativePath, httpMethod: .put, payload: payload, responseDeserializer: voidDeserializer, options: options)
        return httpStatus
    }
    
    
    /// Performs a DELETE request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server or nil together with returned successful httpStatus.
    public func delete<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .delete, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Performs a PATCH request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server or nil together with returned successful httpStatus.
    public func patch<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode)  {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .patch, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
}



// MARK: Adding cookie handling capabilities to RestApiCaller

extension RestApiCaller {
    
    public func httpCookies() -> [HTTPCookie] {
        return httpCookieStorage?.cookies ?? []
    }
    
    public func deleteAllCookies() {
        self.httpCookieStorage?.removeCookies(since: Date())
    }
    
    public func httpCookies(for url: URL) -> [HTTPCookie]? {
        self.httpCookieStorage?.cookies(for: url)
    }
}
