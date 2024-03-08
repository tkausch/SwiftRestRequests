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


import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


/// `URLRequestAuthenticator` will a authentication
public protocol URLRequestAuthorizer {
    /// Configures URL request authorization header
    func configureAuthorizationHeader(for urlRequest: inout URLRequest);
}

/// `AuthorizationDelegate` used to configure HTTP header for basic authorization.
public class BasicRequestAuthorizer: URLRequestAuthorizer {
    
    public let username: String
    public let password: String

    private let headerValue: String
    
    /// Cretae basic authorization with `username` and `password`.
    /// - Parameters:
    ///   - username: The username to be used for authorization
    ///   - password: The password to be used for authorization
    public init(username: String, password: String) {
        self.username = username
        self.password = password

        /// Pre-calculate the header value so we don't do the conversion and encoding on each call
        let credentials = "\(self.username):\(self.password)"
        let base64EncodedCredentials = credentials.data(using: .utf8)!.base64EncodedString()
        self.headerValue = "Basic \(base64EncodedCredentials)"
    }

    public func configureAuthorizationHeader(for urlRequest: inout URLRequest) {
        urlRequest.setValue(self.headerValue, forHTTPHeaderField: "Authorization")
    }
}

/// `AuthorizationDelegate` used to configure HTTP header for bearer authorization.
public class BearerReqeustAuthorizer: URLRequestAuthorizer {
    
    // The token value (without `Bearer` prefix) to be used for the HTTP `Authorization` request header.
    public var token: String
    
    /// Createt bearer authorization with given `token`
    /// - Parameter token: Already base 64 encodced token used for bearer
    public init(token: String) {
        self.token = token
    }
    
    public func configureAuthorizationHeader(for urlRequest: inout URLRequest) {
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}


public class NoneAuthorizer: URLRequestAuthorizer {
    
    public init() {}
    
    public func configureAuthorizationHeader(for urlRequest: inout URLRequest) {
        // do nothing!
    }
}
