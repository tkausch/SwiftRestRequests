//
// Logger+Extension.swift
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

import Logging

extension Logger: Sendable {

    static let labelPrefix = "com.swisscom.swiftRestRequests."
    
    public struct SwiftRestRequests {
        public static let interceptor = Logger(label: labelPrefix + "Interceptor")
        public static let security = Logger(label: labelPrefix + "Security")
        public static let apiCaller = Logger(label: labelPrefix + "ApiCaller")
    }
}


