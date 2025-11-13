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
/// Every case carries additional context so that callers can decide whether to retry, surface the failure,
/// or attempt to recover (for example when a deserializer reports malformed data).
public enum RestError: Error {

    /// The server responded with a non-HTTP response or an unsupported protocol.
    /// - Parameters:
    ///   - response: The raw `URLResponse` returned by the loading system.
    ///   - data: The raw response body bytes (may be empty).
    case badResponse(response: URLResponse, data: Data)

    /// The response `Content-Type` did not match expected MIME types.
    /// - Parameter mimeType: The value of the `Content-Type` header, if any.
    case invalidMimeType(mimeType: String?)

    /// One or more query parameters could not be encoded (percent-encoding failure).
    case invalidQueryParameter

    /// The response body could not be deserialized into the expected model.
    /// - Parameters:
    ///   - response: The `HTTPURLResponse` that accompanied the body.
    ///   - data: The raw response body.
    ///   - underlying: The underlying parsing/decoding error (commonly `DecodingError`).
    case malformedResponse(response: HTTPURLResponse, data: Data, underlying: any Error)

    /// The API returned an error HTTP status and, optionally, a parsed error payload.
    /// - Parameters:
    ///   - response: The `HTTPURLResponse` returned by the server.
    ///   - status: The `HTTPStatusCode` for the response.
    ///   - errorPayload: An optional deserialized error object returned by the API.
    case failedRestCall(response: HTTPURLResponse, status: HTTPStatusCode, errorPayload: (any Sendable)?)

    /// The HTTP status code was not in the set of expected codes.
    /// Configure `RestOptions.expectedStatusCodes` to accept additional codes.
    /// - Parameter statusCode: The unexpected HTTP status code.
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
