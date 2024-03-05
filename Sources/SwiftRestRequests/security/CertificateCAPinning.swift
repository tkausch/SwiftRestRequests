//
// CertificateCAPinning.swift
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


open class CertificateCAPinning: NSObject, URLSessionDelegate {
    
    let pinnedCACertificates: [SecCertificate]
    
    public init(pinnedCACertificates: [SecCertificate]) {
        self.pinnedCACertificates = pinnedCACertificates
        super.init()
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
        // Set the pinned CA certificates for validation
        SecTrustSetAnchorCertificates(serverTrust, pinnedCACertificates as CFArray)
        SecTrustSetAnchorCertificatesOnly(serverTrust, true)
        
        // Perform certificate chain validation
        var error: CFError? = nil
        let status = SecTrustEvaluateWithError(serverTrust, &error)
        
        if error == nil && status {
                return (.useCredential, URLCredential(trust: serverTrust))
        } else {
            return (.cancelAuthenticationChallenge, nil)
        }
        
    }
    
    
}
