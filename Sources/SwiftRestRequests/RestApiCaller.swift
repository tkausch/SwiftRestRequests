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

@preconcurrency import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Logging


// MARK: - Protocols used by RestapiCaller

/// Closure invoked before a request is sent to assemble additional HTTP headers.
///
/// The generated headers are merged with the headers specified per call. Keys returned by the closure override
/// existing values, making it convenient to inject authentication or device metadata that changes at runtime.
public typealias HeaderGenerator = @Sendable (URL) -> [String : String]?

/// Abstraction for intercepting outgoing requests and incoming responses.
///
/// Interceptors can mutate the `URLRequest` before it is sent or observe the `HTTPURLResponse` and payload
/// after it is received. Register interceptors on `RestApiCaller` to build cross-cutting features such as
/// logging, analytics, or header injection.
@preconcurrency public protocol URLRequestInterceptor: AnyObject {
    /// Called immediately before the request is executed. Mutate `request` in place to apply changes.
    func invokeRequest(request: inout URLRequest, for session: URLSession);
    /// Called after the response has been received. The default implementation does nothing.
    func receiveResponse(data: Data, response: HTTPURLResponse, for session: URLSession);
}

extension URLRequestInterceptor {
    /// Default no-op implementation to make `receiveResponse` optional for conformers.
    public func receiveResponse(data: Data, response: HTTPURLResponse, for session: URLSession) {
        // default empty implementation for optional method
    }
}

// MARK: - The Main class

/// High-level HTTP client that handles JSON encoding/decoding, status validation, and error mapping.
///
/// **NOTE:** Ensure to configure `App Transport Security` appropriately.
open class RestApiCaller : NSObject {
    
    /// Shared logger used to emit diagnostic messages for the caller lifecycle.
    let logger = Logger.SwiftRestRequests.apiCaller

    /// Backing `URLSession` used to execute requests.
    let session: URLSession
    /// Base URL that relative endpoint paths are appended to.
    let baseUrl: URL
    /// Optional deserializer for error payloads.
    let errorDeserializer: (any Deserializer)?
    /// Cookie storage used by the session (if provided).
    let httpCookieStorage: HTTPCookieStorage?
   
    private let interceptorLock = NSLock()
    
    /// Registered request/response interceptors (empty by default).
    var interceptors: [URLRequestInterceptor] = []
    
    /// Closure used to generate dynamic headers prior to each request.
    public let headerGenerator: HeaderGenerator?
    
    /// Authorizer that can mutate requests with authentication information.
    public let authorizer: (any URLRequestAuthorizer)?

// MARK: Lifecycle
    
    
    /// Convenience initializer that provisions its own `URLSession` from the supplied configuration.
    /// - Parameters:
    ///   - baseUrl: The base URL for all subsequent REST calls.
    ///   - sessionConfig: Configuration used to create the underlying `URLSession`.
    ///   - authorizer: Optional request authorizer added as an interceptor.
    ///   - errorDeserializer: Custom deserializer for error payloads.
    ///   - headerGenerator: Closure producing dynamic headers per request.
    ///   - enableNetworkTrace: When `true`, installs `LogNetworkInterceptor` (non-Linux platforms only).
    ///   - httpCookieStorage: Optional cookie storage injected into the session configuration.
    public convenience init(baseUrl: URL, sessionConfig:  
                            URLSessionConfiguration = URLSessionConfiguration.default,
                            authorizer: (any URLRequestAuthorizer)? = nil,
                            errorDeserializer: (any Deserializer)? = nil,
                            headerGenerator: HeaderGenerator? = nil,
                            enableNetworkTrace: Bool = false,
                            httpCookieStorage: HTTPCookieStorage? = nil) {
        
        if let httpCookieStorage {
            sessionConfig.httpCookieAcceptPolicy = .always
            sessionConfig.httpShouldSetCookies = true
            sessionConfig.httpCookieStorage = httpCookieStorage
        }
        
        self.init(baseUrl: baseUrl, urlSession: URLSession(configuration: sessionConfig), authorizer: authorizer, errorDeserializer: errorDeserializer, headerGenerator: headerGenerator, enableNetworkTrace: enableNetworkTrace, httpCookieStorage: httpCookieStorage)
    }

    
    /// Designated initializer that accepts a pre-configured `URLSession`.
    /// - Parameters:
    ///   - baseUrl: The base URL to which requests are sent.
    ///   - urlSession: Pre-built session used for network requests. Configure delegates or caching as needed.
    ///   - authorizer: Optional request authorizer added as an interceptor.
    ///   - errorDeserializer: Custom deserializer for error payloads.
    ///   - headerGenerator: Closure producing dynamic headers per request.
    ///   - enableNetworkTrace: Enables network tracing through `LogNetworkInterceptor` (non-Linux platforms).
    ///   - httpCookieStorage: Cookie storage associated with the session.
    public init(baseUrl: URL, urlSession: URLSession, authorizer: (any URLRequestAuthorizer)?, errorDeserializer: (any Deserializer)?, headerGenerator: HeaderGenerator?, enableNetworkTrace: Bool, httpCookieStorage: HTTPCookieStorage?) {
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
        for interceptor in interceptors {
            interceptor.invokeRequest(request: &request, for: session)
        }
    }
    @inline(__always)
    private func callReceiveInterceptors(_ data: Data, _ response: HTTPURLResponse) {
        // reverse the order for response handling so the most recently added interceptor observes the response first
        for interceptor in interceptors.reversed() {
            interceptor.receiveResponse(data: data, response: response, for: session)
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
            throw RestError.unexpectedHttpStatusCode(statusCode: httpResponse.statusCode)
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
            throw RestError.badResponse(response: response, data: data)
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
        if shouldBypassDeserialization(responseDeserializer, status: httpStatus),
           httpStatus.type == .success {
            return (nil, httpStatus)
        }
        
        guard !data.isEmpty  else {
            throw RestError.failedRestCall(response: httpResponse, status: httpStatus, errorPayload: nil)
        }
        
        // Postcondition: We have a response object or  error that needs to be parsed!
        
        _ = try validatedMimeType(from: httpResponse)
        
        if httpStatus.type == .success  {
            let transformedResponse = try decodeSuccessfulResponse(data: data, response: httpResponse, deserializer: responseDeserializer)
            return (transformedResponse, httpStatus)
        }

        throw try buildErrorResponse(data: data, response: httpResponse, status: httpStatus)
    }

    private func shouldBypassDeserialization<T: Deserializer>(_ deserializer: T, status: HTTPStatusCode) -> Bool {
        (deserializer is VoidDeserializer) || status == .noContent
    }

    private func validatedMimeType(from response: HTTPURLResponse) throws -> MimeType {
        let contentType = response.value(forHTTPHeaderField: HTTPHeaderKeys.ContentType.rawValue)
        let firstContentMimeType = contentType?.components(separatedBy: ";").first
        
        guard let firstContentMimeType,
              let mimeType = MimeType(rawValue: firstContentMimeType) else {
            throw RestError.invalidMimeType(mimeType: contentType)
        }
        return mimeType
    }
    
    private func decodeSuccessfulResponse<T: Deserializer>(data: Data, response: HTTPURLResponse, deserializer: T) throws -> T.ResponseType? {
        if response.status == .ok {
            do {
                return try deserializer.deserialize(data)
            } catch {
                throw RestError.malformedResponse(response: response, data: data, underlying: error)
            }
        }
        return nil
    }

    private func buildErrorResponse(data: Data, response: HTTPURLResponse, status: HTTPStatusCode) throws -> RestError {
        do {
            let errorPayload = try errorDeserializer?.deserialize(data)
            return RestError.failedRestCall(response: response, status: status, errorPayload: errorPayload)
        } catch {
            throw RestError.malformedResponse(response: response, data: data, underlying: error)
        }
    }
    
    
// MARK: Public API that can be used from other classes or subclass
    
    /// Registers a request interceptor to observe or mutate network traffic.
    /// Interceptors run in the order they are registered and share the caller's `URLSession` instance.
    /// - Parameter interceptor: Interceptor appended to the invocation chain.
    public func registerRequestInterceptor(_ interceptor: any URLRequestInterceptor) {
        logger.info("Registering request interceptor: \(interceptor)")
        
        interceptorLock.lock()
        defer { interceptorLock.unlock() }
        
        interceptors.append(interceptor)
    }
    
    /// Executes an asynchronous `GET` request and decodes the JSON response.
    /// - Parameters:
    ///   - type: The expected response type used for generic inference.
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: Tuple containing the decoded response (only returned for `200 OK`) and the response status code.
    public func get<D: Decodable & Sendable>(_ type: D.Type, at relativePath: String?, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .get, payload: nil, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Executes an asynchronous `GET` request that expects an empty body.
    /// - Parameters:
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: HTTP status returned by the server.
    public func get(at relativePath: String?, options: RestOptions = RestOptions()) async throws -> HTTPStatusCode {
        let decodableDeserializer = VoidDeserializer()
        let ( _ , httpStatus) = try await makeCall(relativePath, httpMethod: .get, payload: nil, responseDeserializer: decodableDeserializer, options: options)
        return httpStatus
    }

    /// Executes an asynchronous `POST` request and decodes the JSON response.
    /// - Parameters:
    ///   - encodable: Request payload encoded as JSON.
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - type: The expected response type used for generic inference.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: Tuple containing the decoded response (only returned for `200 OK`) and the response status code.
    public func post<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .post, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    
    /// Executes an asynchronous `POST` request that expects an empty response body.
    /// - Parameters:
    ///   - encodable: Request payload encoded as JSON.
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: HTTP status returned by the server.
    public func post<E: Encodable>(_ encodable: E, at relativePath: String?, options: RestOptions = RestOptions()) async throws -> HTTPStatusCode {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = VoidDeserializer()
        let ( _ , httpStatus) = try await makeCall(relativePath, httpMethod: .post, payload: payload, responseDeserializer: decodableDeserializer, options: options)
        return httpStatus
    }
    
    
    
    /// Executes an asynchronous `PUT` request and decodes the JSON response.
    /// - Parameters:
    ///   - encodable: Request payload encoded as JSON.
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - type: The expected response type used for generic inference.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: Tuple containing the decoded response (only returned for `200 OK`) and the response status code.
    public func put<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .put, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Performs a PUT request to the server, capturing the HTTP response status.
    ///
    /// Executes an asynchronous `PUT` request that expects an empty response body.
    /// - Parameters:
    ///   - encodable: Request payload encoded as JSON.
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: HTTP status returned by the server.
    public func put<E: Encodable>(_ encodable: E, at relativePath: String?, options: RestOptions = RestOptions()) async throws -> HTTPStatusCode {
        let payload = try JSONEncoder().encode(encodable)
        let voidDeserializer = VoidDeserializer()
        let (_, httpStatus) = try await makeCall(relativePath, httpMethod: .put, payload: payload, responseDeserializer: voidDeserializer, options: options)
        return httpStatus
    }
    
    
    /// Executes an asynchronous `DELETE` request and decodes the JSON response.
    /// - Parameters:
    ///   - encodable: Request payload encoded as JSON.
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - type: The expected response type used for generic inference.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: Tuple containing the decoded response (only returned for `200 OK`) and the response status code.
    public func delete<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .delete, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Executes an asynchronous `PATCH` request and decodes the JSON response.
    /// - Parameters:
    ///   - encodable: Request payload encoded as JSON.
    ///   - relativePath: Path appended to the base URL. Pass `nil` to target the base URL without additional path components.
    ///   - type: The expected response type used for generic inference.
    ///   - options: Per-call overrides such as headers, query parameters, timeouts, or expected status codes.
    /// - Returns: Tuple containing the decoded response (only returned for `200 OK`) and the response status code.
    public func patch<E: Encodable, D: Decodable & Sendable>(_ encodable: E, at relativePath: String?, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, HTTPStatusCode)  {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .patch, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
}



// MARK: Adding cookie handling capabilities to RestApiCaller

extension RestApiCaller {
    
    /// Returns every cookie currently tracked by the caller.
    public func httpCookies() -> [HTTPCookie] {
        return httpCookieStorage?.cookies ?? []
    }
    
    /// Removes all cookies from the underlying storage.
    public func deleteAllCookies() {
        self.httpCookieStorage?.removeCookies(since: Date())
    }
    
    /// Returns cookies that match the supplied URL.
    /// - Parameter url: URL used to scope the lookup.
    /// - Returns: Cookies for the given URL, or `nil` if no cookie storage is configured.
    public func httpCookies(for url: URL) -> [HTTPCookie]? {
        self.httpCookieStorage?.cookies(for: url)
    }
}
