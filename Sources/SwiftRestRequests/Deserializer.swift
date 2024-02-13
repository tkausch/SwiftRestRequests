//
//  Deserializer.swift
//
//
//  Created by Thomas Kausch on 06.02.2024.
//


import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif


/// Protocol for de-serializing responses from the web server.
public protocol Deserializer {

    associatedtype ResponseType = Any

    /// The `Accept` Hader to send in the request, ex: `application/json`
    var acceptHeader: String { get }

    init()

    /// Deserializes the data returned by the web server to the desired type.
    /// - parameter data: The data returned by the server.
    /// - returns: The deserialized value of the desired type.
    func deserialize(_ data: Data) throws -> ResponseType
}


/// A `Deserializer` for Swift 4's `Decodable` protocol
public final class DecodableDeserializer<T: Decodable>: Deserializer {

    public typealias ResponseType = T

    public let acceptHeader = MimeType.Json.rawValue

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

    public let acceptHeader = MimeType.OctetStream.rawValue

    public required init() { }

    public func deserialize(_ data: Data) throws -> Data {
        return data
    }
}
