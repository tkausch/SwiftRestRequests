//
// Deserializer.swift
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

/// Protocol for de-serializing responses from the web server.
public protocol Deserializer {

    associatedtype ResponseType: Sendable

    /// The `Accept` Hader to send in the request, ex: `application/json`
    var acceptHeader: String { get }

    init()

    /// Deserializes the data returned by the web server to the desired type.
    /// - parameter data: The data returned by the server.
    /// - returns: The deserialized value of the desired type.
    func deserialize(_ data: Data) throws -> ResponseType
}


/// A `Deserializer` for Swift 4's `Decodable` protocol
public final class DecodableDeserializer<T: Decodable & Sendable>: Deserializer {

    public typealias ResponseType = T

    public let acceptHeader = MimeType.ApplicationJson.rawValue

    public init() { }

    public func deserialize(_ data: Data) throws -> T {
        return try JSONDecoder().decode(T.self, from: data)
    }
}


/// A `Deserializer` for `Void` (for use with servers that return no data).
public final class VoidDeserializer: Deserializer {

    public typealias ResponseType = Void

    public let acceptHeader = MimeType.Void.rawValue

    public init() { }
    
    public func deserialize(_ data: Data) throws -> Void {
        assert(data.isEmpty) // no data should be returned
        return Void()
    }
}


/// A `Deserializer` for `Data`
public final class DataDeserializer: Deserializer {

    public typealias ResponseType = Data

    public let acceptHeader = MimeType.ApplicationOctetStream.rawValue

    public required init() { }

    public func deserialize(_ data: Data) throws -> Data {
        return data
    }
}
