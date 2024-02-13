# SwiftRestRequests
SwiftRestRequests is an elegant and simple REST library for Swift, built for human beings and can be used on iOS, iPadOS, macOS, tvOS, and watchOS.

This Package allows you to send REST requests extremely easily using HTTP/1.1 or HTTP/2. Thanks to Swift 4's Codable support JSON Response and Request objects are fully type validated.

The optional `RestOption` object supports the setting of specific HTTP headers, query parameters and HTTP timeout for each REST request.  

The Package is using HTTP client transport that uses the `URLSession` type from the `Foundation` framework to perform HTTP operations. Therfore it is flexible to add other 

## Features

- [x] Easily perform asynchronous REST networking calls (GET, POST, PUT, PATCH, or DELETE) that send JSON
- [x] Easy API that uses Swift's async/await syntax
- [x] Natively integrates with Swift's Decodable and Encodable types
- [x] HTTP response validation
- [x] Send custom HTTP headers
- [x] Change timeout options
- [x] Fully native Swift API

### Requirements

SwiftRestRequests 1.0 and newer works with any of the supported operating systems listed below with the version of Xcode.

- iOS 15.0+
- tvOS 15.0+
- watchOS 8.0+
- iPadOS 15.0+
- macOS 12.0+

### Swift Package Manager

SwiftRestRequests is compatible with the SPM for macOS, iOS, iPadOS, tvOS, and watchOS (not avaiale on Linux at this time). When using XCode 11, the Swift Package Manager is the recommended installation method.

To use in XCode 11+, open your project and go to ```File->Swift Packages->Add Package Dependency...``` and follow along the dialogs. Thats it!

If you prefer to add it manually using SPM, just add the SwiftRestRequests dependency to your target in your ```Package.swift``` file.

```swift
dependencies: [
.package(url: "https://github.com/tkausch/SwiftRestRequests", from: "0.9")
]
```
