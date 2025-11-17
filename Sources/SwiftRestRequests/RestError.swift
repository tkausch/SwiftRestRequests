//
// RestError.swift
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

/// Errors thrown when executing REST requests.
///
/// `RestError` provides comprehensive error information for REST API operations, allowing callers to
/// make informed decisions about error handling, retry strategies, and recovery options.
///
/// ## Overview
/// This error type encapsulates various failure scenarios that can occur during REST API interactions:
/// - Invalid response formats or protocols
/// - Unexpected MIME types
/// - Query parameter encoding issues
/// - Response deserialization failures
/// - HTTP status code violations
/// - Server-reported errors
///
/// ## Topics
///
/// ### Response Validation Errors
/// - ``badResponse(_:_:)``
/// - ``invalidMimeType(_:)``
/// - ``unexpectedHttpStatusCode(_:)``
///
/// ### Data Processing Errors
/// - ``malformedResponse(_:_:_:)``
/// - ``invalidQueryParameter``
///
/// ### API Errors
/// - ``failedRestCall(_:_:error:)``
///
/// ## Usage Example
/// ```swift
/// do {
///     let result = try await restClient.get("https://api.example.com/data")
/// } catch let error as RestError {
///     switch error {
///     case .invalidMimeType(let mime):
///         print("Unexpected content type: \(mime ?? "none")")
///     case .failedRestCall(_, let status, let error):
///         print("API error: \(status), details: \(error ?? "none")")
///     case .malformedResponse(_, _, let error):
///         print("Failed to parse response: \(error)")
///     // Handle other cases...
///     }
/// }
/// ```
public enum RestError: Error {

    /// Indicates that the server responded using an unknown or unsupported protocol.
    ///
    /// This error occurs when the server's response doesn't conform to the expected HTTP/HTTPS protocol
    /// or when the response format is invalid.
    ///
    /// - Parameters:
    ///   - URLResponse: The raw response returned from the server.
    ///   - Data: The raw data returned in the response body.
    ///
    /// - Note: This error typically indicates a server misconfiguration or a proxy interference.
    case badResponse(response: URLResponse, data: Data)

    /// Indicates that the server responded with an unexpected MIME type.
    ///
    /// This error occurs when the Content-Type header in the response doesn't match
    /// the expected MIME type for the request. For example, receiving "text/plain"
    /// when "application/json" was expected.
    ///
    /// - Parameter String: The MIME type received in the response's Content-Type header.
    ///                    May be nil if no Content-Type header was present.
    ///
    /// - Note: Configure `RestOptions.acceptedMimeTypes` to specify additional accepted MIME types.
    case invalidMimeType(mimeType: String?)

    /// Indicates that query parameters could not be encoded using percent encoding.
    ///
    /// This error occurs when attempting to encode query parameters into a URL-safe format
    /// using percent encoding, but the encoding operation fails. This typically happens when
    /// parameter values contain characters that cannot be safely encoded for URL transmission.
    ///
    /// - Note: To avoid this error, ensure query parameters contain only URL-safe characters
    ///         or properly encode special characters before making the request.
    case invalidQueryParameter

    /// Indicates the server's response could not be deserialized using the given Deserializer.
    ///
    /// This error occurs when the response data cannot be converted into the expected type
    /// using the configured Deserializer. Common causes include:
    /// - Mismatched data structure
    /// - Missing required fields
    /// - Invalid data types
    /// - Malformed JSON or other formats
    ///
    /// - Parameters:
    ///   - HTTPURLResponse: The HTTP response metadata from the server.
    ///   - Data: The raw response data that failed to deserialize.
    ///   - Error: The underlying error (typically a `DecodingError`) that provides
    ///            specific details about why deserialization failed.
    ///
    /// - Note: Inspect the underlying Error for detailed information about the deserialization failure.
    ///         For DecodingError cases, the error will contain the specific path where decoding failed.
    case malformedResponse(response: HTTPURLResponse, data: Data, underlying: any Error)

   /// Indicates the API call failed with an error response from the server.
    ///
    /// This error represents a failed API call where the server returned an error response.
    /// The error includes the full HTTP response, the specific status code, and optionally
    /// a parsed error payload from the response body.
    ///
    /// - Parameters:
    ///   - HTTPURLResponse: The complete HTTP response containing headers and metadata.
    ///   - HTTPStatusCode: The specific HTTP status code indicating the type of failure.
    ///   - error: The deserialized error payload from the response body, if one was
    ///            provided and could be parsed. The error payload must conform to `Sendable`.
    ///
    /// ## Example
    /// ```swift
    /// catch case let RestError.failedRestCall(response, status, error) {
    ///     print("API call failed with status: \(status)")
    ///     if let apiError = error as? MyAPIError {
    ///         print("Error details: \(apiError)")
    ///     }
    /// }
    /// ```
    case failedRestCall(response: HTTPURLResponse, status: HTTPStatusCode, errorPayload: (any Sendable)?)

    /// Indicates that the response contained an unexpected HTTP status code.
    ///
    /// This error occurs when the server returns an HTTP status code that isn't in the
    /// set of expected status codes for the request. By default, only 2xx status codes
    /// are considered valid.
    ///
    /// - Parameter Int: The unexpected HTTP status code returned from the server.
    ///
    /// - Note: You can configure additional valid status codes using `RestOptions.expectedStatusCodes`.
    ///         This is useful when certain error codes should be treated as valid responses
    ///         for your specific use case.
    ///
    /// ## Example
    /// ```swift
    /// // Configure 404 as valid for this request
    /// var options = RestOptions()
    /// options.expectedStatusCodes = [200, 404]
    /// ```   
    case unexpectedHttpStatusCode(statusCode: Int)


}

// MARK: - LocalizedError and debug helpers

extension RestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .badResponse:
            return "Received an unsupported or invalid response from the server."
        case .invalidMimeType(let mime):
            return "Unexpected content type: \(mime ?? "unknown")."
        case .invalidQueryParameter:
            return "Failed to encode query parameters."
        case .malformedResponse(_, _, let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        case .failedRestCall(_, let status, _):
            return "Server returned an error (status: \(status))."
        case .unexpectedHttpStatusCode(let code):
            return "Unexpected HTTP status code: \(code)."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidQueryParameter:
            return "Verify parameter values and percent-encode reserved characters."
        case .malformedResponse:
            return "Confirm the response schema matches the expected model and enable payload logging in debug builds."
        default:
            return nil
        }
    }
}

extension RestError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .badResponse(let response, let data):
            return "RestError.badResponse(url: \(response.url?.absoluteString ?? "n/a"), size: \(data.count))"
        case .invalidMimeType(let mime):
            return "RestError.invalidMimeType(mime: \(mime ?? "nil"))"
        case .invalidQueryParameter:
            return "RestError.invalidQueryParameter"
        case .malformedResponse(let response, let data, let underlying):
            return "RestError.malformedResponse(status: \(response.statusCode), size: \(data.count), underlying: \(underlying))"
        case .failedRestCall(let response, let status, let payload):
            return "RestError.failedRestCall(status: \(status), url: \(response.url?.absoluteString ?? "n/a"), payload: \(String(describing: payload)))"
        case .unexpectedHttpStatusCode(let code):
            return "RestError.unexpectedHttpStatusCode(\(code))"
        }
    }
}

// MARK: - Equatable (useful for tests)

extension RestError: Equatable {
    public static func == (lhs: RestError, rhs: RestError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidQueryParameter, .invalidQueryParameter):
            return true
        case (.invalidMimeType(let a), .invalidMimeType(let b)):
            return a == b
        case (.unexpectedHttpStatusCode(let a), .unexpectedHttpStatusCode(let b)):
            return a == b
        case (.badResponse(let la, let ld), .badResponse(let ra, let rd)):
            return la.url?.absoluteString == ra.url?.absoluteString && ld == rd
        case (.malformedResponse(let la, _, _), .malformedResponse(let ra, _, _)):
            return la.statusCode == ra.statusCode
        case (.failedRestCall(_, let aStatus, _), .failedRestCall(_, let bStatus, _)):
            return aStatus == bStatus
        default:
            return false
        }
    }
}
