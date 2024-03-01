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

### Usage

SwiftRequests is best used with Swift 4's native JSON support. For each service you should implement the corresponding Request and response struct using `Encodable` and `Decodable` protocol. Then you are able to call the REST service using the required HTTP method with the `RestAPICaller`. A best practice is to subclass RestApiCaller and implement a method for each of your REST service endpoints. These methods will delegate to the `get, post, put, delete or put`methods. 


#### Making a GET Request and getting back a Response object

```
import SwiftRestRequests

struct HttpBinResponse: Decodable {
    let url: String
    let origin: String
    let headers: HttpBinHeaders
}

guard let url = URL(string: "https://httpbin.org") else {
    Print("Bad server URL!")
    return
}
apiCaller = RestApiCaller(baseUrl: url)

let (response, httpStatus) = try await apiCaller.get(HttpBinResponse.self, at: "get")

print("HttpStatus: \(httpStatus)")

```
#### Making a POST Request using a Swift 4 Encodable Request object and getting back a Decodable Response object


```
import SwiftRestRequests

struct HttpBinRequest: Encodable {
	let key1: String
	let key2: Int
	let key3: Float
	let key4: Bool
	let key5: [Int]
}
        
struct HttpBinResponse: Decodable {
	let json: HttpBinRequest
}

let request = HttpBinRequest(key1: "Hello", key2: 1, key3: 2.0, key4: true, key5: [1,2,3,4,5])
        
        
let (response, httpStatus) = 
	try await apiCaller.post(request, at: "post", responseType: HttpBinResponse.self)

print("\(response?.json)"

```


