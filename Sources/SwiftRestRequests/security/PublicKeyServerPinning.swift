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



/// Use this URLSession delegate to implement public key server  pinning.
/// Note: You  need to assign this object as  delegate for the `URLSession` object.
open class PublicKeyServerPinning: NSObject, URLSessionDelegate {
    
    let pinnedPublicKeys: [SecKey]
    
    public init(pinnedPublicKeys: [SecKey]) {
        self.pinnedPublicKeys = pinnedPublicKeys
        super.init()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return(.cancelAuthenticationChallenge, nil)
        }
        
        // Extract the server's public key
        if let serverPublicKey = SecTrustCopyKey(serverTrust) {
            // Compare the server's public key with the pinned public key
            if pinnedPublicKeys.contains(where: { publicKey in
                publicKey == serverPublicKey
            }) {
                return (.useCredential, URLCredential(trust: serverTrust))
            } else {
                return (.cancelAuthenticationChallenge, nil)
            }
        } else {
            return (.cancelAuthenticationChallenge, nil)
        }
    }
    
}




