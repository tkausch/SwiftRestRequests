//
//  File.swift
//  
//
//  Created by Thomas Kausch on 06.02.2024.
//

import Foundation


/// Allows users to generate headers before each REST call is made. The headers returned will be COMBINED with
/// any headers set in the original `RestCaller` call. Any headers returned here will override the values given
/// in the original call if they have the same name.
///
/// - parameter requestUrl: The URL that this header generation request is for. Never nu,,
public typealias HeaderGenerator = (URL) -> [String : String]?


/// Allows users to create HTTP REST networking calls that deal with JSON.
///
/// **NOTE:** Ensure to configure `App Transport Security` appropriately.
public class RestApiCaller : NSObject {

    private var session: URLSession
    private var baseUrl: URL
    private var errorDeserializer: (any Deserializer)?

    
    /// This generator will be called before every useage of this RestController
    public var headerGenerator: HeaderGenerator?

    
    public init(baseUrl: URL, sessionConfig:  URLSessionConfiguration = URLSessionConfiguration.default, errorDeserializer: (any Deserializer)? = nil) {
        self.baseUrl = baseUrl
        self.session = URLSession(configuration: sessionConfig)
        self.errorDeserializer = errorDeserializer
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
        
        let restURL: URL;
        if let relativeURL = relativePath {
            restURL = baseUrl.appendingPathComponent(relativeURL)
        } else {
            restURL = baseUrl
        }

        // Create URLRequest with default cache policy using the timeout from rest options
        var request = URLRequest(url: restURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: options.requestTimeoutSeconds)
        request.httpMethod = httpMethod

        // Set general headers from REST option object
        request.setValue(MimeType.Json.rawValue, forHTTPHeaderField: HttpHeaders.Accept.rawValue)
        if let customHeaders = options.httpHeaders {
            for (httpHeaderKey, httpHeaderValue) in customHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }

        // Append rest endpoint specific headers i.e. JWT tokens for authentication
        if let generatedHeaders = headerGenerator?(restURL) {
            for (httpHeaderKey, httpHeaderValue) in generatedHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }

        // set data with json payload ...
        if let payloadToSend = payload {
            request.setValue(MimeType.Json.rawValue, forHTTPHeaderField: HttpHeaders.ContentType.rawValue)
            request.httpBody = payloadToSend
        }

        // make remote call
        let (data, response) = try await session.data(for: request)
        
        // check http response has a supported type
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RestError.badResponse(response, data)
        }

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
    private func makeCall<T: Deserializer>(_ relativePath: String?, httpMethod: RestMethod, payload: Data?, responseDeserializer: T, options: RestOptions) async throws -> (T.ResponseType?, Int) {
        let (data, httpResponse) = try await dataTask(relativePath: relativePath, httpMethod: httpMethod.rawValue, accept: responseDeserializer.acceptHeader, payload: payload, options: options)
        
        // Validate http response - content-type MUST be set or empty data
        if let contentType = httpResponse.value(forHTTPHeaderField: HttpHeaders.ContentType.rawValue) {
            if !data.isEmpty && contentType != MimeType.Json.rawValue {
                throw RestError.badResponse(httpResponse, data)
            }
        }
         
        let successRange = 200...299
        if successRange.contains(httpResponse.statusCode)  {
            do {
                if !data.isEmpty {
                    let transformedResponse = try responseDeserializer.deserialize(data)
                    return (transformedResponse, httpResponse.statusCode)
                } else {
                    // when no data is returned but http status represents success i.e. 204
                    return (nil, httpResponse.statusCode)
                }
            } catch {
                throw RestError.malformedResponse(httpResponse, data, error)
            }
        }
        
        // Postcondition: Unsuccessful call and data COULD contain error json object
        do {
            let errorJson = try errorDeserializer?.deserialize(data)
            throw RestError.failedRestCall(httpResponse, httpResponse.statusCode, errorJson)
        } catch {
            throw RestError.malformedResponse(httpResponse, data, error)
        }
        
    }

    /// Performs a GET request to the server, capturing the data object type response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter type: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` type of `D` object that was returned from the server or nil together with returned successful httpStatus.
    public func get<D: Decodable>(_ type: D.Type, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> (D?, Int) {
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .Get, payload: nil, responseDeserializer: decodableDeserializer, options: options)
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
    public func post<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, Int) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .Post, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    
    /// Performs a POST request to the server without capturing response. Only successful httpStatus is returned!
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: Returns  successful httpStatus
    public func post<E: Encodable>(_ encodable: E, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> Int {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = VoidDeserializer()
        let ( _ , httpStatus) = try await makeCall(relativePath, httpMethod: .Post, payload: payload, responseDeserializer: decodableDeserializer, options: options)
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
    public func put<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, Int) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .Put, payload: payload, responseDeserializer: decodableDeserializer, options: options)
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
    public func delete<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, Int) {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .Delete, payload: payload, responseDeserializer: decodableDeserializer, options: options)
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
    public func patch<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> (D?, Int)  {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: .Patch, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
}
