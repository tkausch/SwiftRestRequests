//
// URLRequestAuthorizer.swift
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
import Logging

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif



/// Protocol adopted by components that can apply authentication headers to requests.
public protocol URLRequestAuthorizer: Sendable {
    /// Updates the request with the appropriate authorization header.
    func configureAuthorizationHeader(for urlRequest: inout URLRequest);
}

/// Configures `Authorization` headers for HTTP Basic authentication.
public final class BasicRequestAuthorizer: URLRequestAuthorizer {
    
    let logger: Logger
    
    public let username: String
    public let password: String

    private let headerValue: String
    
    /// Creates a Basic authorization header from the provided credentials.
    /// - Parameters:
    ///   - username: The username to be used for authorization
    ///   - password: The password to be used for authorization
    ///   - logger: Destination for security trace logging.
    public init(username: String, password: String, logger: Logger = Logger.SwiftRestRequests.security) {
        self.username = username
        self.password = password
        self.logger = logger

        /// Pre-calculate the header value so we don't do the conversion and encoding on each call
        let credentials = "\(self.username):\(self.password)"
        let base64EncodedCredentials = credentials.data(using: .utf8)!.base64EncodedString()
        self.headerValue = "Basic \(base64EncodedCredentials)"
    }

    /// Applies the precomputed Basic authorization header to the request.
    public func configureAuthorizationHeader(for urlRequest: inout URLRequest) {
        logger.trace("Set HTTP Authorization header",  metadata: [
            "urlRequest": "\(String(describing: urlRequest.url?.absoluteString))",
            "Authorization": "****"])
        urlRequest.setValue(self.headerValue, forHTTPHeaderField: "Authorization")
    }
}

/// Configures `Authorization` headers for Bearer token authentication.
public final class BearerRequestAuthorizer: URLRequestAuthorizer {
    
    let logger: Logger
    
    // The token value (without `Bearer` prefix) to be used for the HTTP `Authorization` request header.
    public let token: String
    
    /// Creates a Bearer authorization helper with the provided token.
    /// - Parameters:
    ///   - token: Token value (without `Bearer` prefix) inserted into the header.
    ///   - logger: Destination for security trace logging.
    public init(token: String, logger: Logger = Logger.SwiftRestRequests.security) {
        self.token = token
        self.logger = logger
    }
    
    /// Applies the Bearer authorization header to the request.
    public func configureAuthorizationHeader(for urlRequest: inout URLRequest) {
        logger.trace("Set HTTP Authorization header", metadata: [
            "Authorization": "Bearer \(self.token)"])
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}


/// No-op authorizer used when requests must remain unauthenticated.
public final class NoneAuthorizer: URLRequestAuthorizer {
    
    public init() {}
    
    /// Leaves the request untouched.
    public func configureAuthorizationHeader(for urlRequest: inout URLRequest) {
        // do nothing!
    }
}
