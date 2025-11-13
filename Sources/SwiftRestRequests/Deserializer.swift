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

/// Deserializes raw network data into strongly typed Swift values.
public protocol Deserializer: Sendable {

    associatedtype ResponseType: Sendable

    /// Value for the `Accept` header sent alongside the request (for example `application/json`).
    var acceptHeader: String { get }

    var jsonDecoder: JSONDecoder? { get }
    
    /// Creates a new instance of the deserializer.
    init()

    /// Deserializes the data returned by the web server to the desired type.
    /// - parameter data: The data returned by the server.
    /// - returns: The deserialized value of the desired type.
    func deserialize(_ data: Data) throws -> ResponseType
}


/// A generic deserializer that uses `JSONDecoder` to decode a `Decodable` value.
public struct DecodableDeserializer<T: Decodable & Sendable>: Deserializer {

    public typealias ResponseType = T

    public var jsonDecoder: JSONDecoder? = JSONDecoder()

    public let acceptHeader = MimeType.ApplicationJson.rawValue

    public init() { }

    public func deserialize(_ data: Data) throws -> T {
        return try jsonDecoder!.decode(T.self, from: data)
    }
}


/// A deserializer representing empty responses (`Void`).
public struct VoidDeserializer: Deserializer {

    public typealias ResponseType = Void

    public var jsonDecoder: JSONDecoder? = nil
    
    public let acceptHeader = MimeType.Void.rawValue

    public init() { }
    
    public func deserialize(_ data: Data) throws -> Void {
        assert(data.isEmpty) // no data should be returned
        return ()
    }
}


/// A deserializer that emits the raw payload `Data`.
public struct DataDeserializer: Deserializer {

    public typealias ResponseType = Data
    
    public var jsonDecoder: JSONDecoder? = nil

    public let acceptHeader = MimeType.ApplicationOctetStream.rawValue

    public init() { }

    public func deserialize(_ data: Data) throws -> Data {
        return data
    }
}
