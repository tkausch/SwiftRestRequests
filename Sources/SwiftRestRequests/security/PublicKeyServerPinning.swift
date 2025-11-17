//
// PublicKeyServerPinning.swift
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

#if os(Linux)
// no public key pinning implemented
#else

@preconcurrency import Security
import Logging

/// URLSession delegate enforcing TLS pinning based on server public keys.
/// Note: Assign an instance as the delegate of the `URLSession` you use for requests.
public final class PublicKeyServerPinning: NSObject,  URLSessionDelegate {
    
    let pinnedPublicKeys: [SecKey]
    
    let logger = Logger.SwiftRestRequests.security
    
    /// Creates a new pinning delegate.
    /// - Parameter pinnedPublicKeys: Collection of allowed server public keys.
    public init(pinnedPublicKeys: [SecKey]) {
        self.pinnedPublicKeys = pinnedPublicKeys
    }
    
    /// Validates the server certificate's public key against the pinned keys.
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
        guard let serverTrust = TrustValidation.extractServerTrust(from: challenge, logger: logger) else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        guard let serverPublicKey = SecTrustCopyKey(serverTrust) else {
            logger.error("Security: public key pinning failed - no key present in server trust.")
            return (.cancelAuthenticationChallenge, nil)
        }
        
        guard pinnedPublicKeys.contains(where: { $0 == serverPublicKey }) else {
            logger.error("Security: public key pinning failed - key not found in pinned set.")
            return (.cancelAuthenticationChallenge, nil)
        }
        
        logger.info("Security: public key pinning succeeded.")
        return (.useCredential, URLCredential(trust: serverTrust))
    }
    
}
#endif
