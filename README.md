# SwiftRestRequests
SwiftRestRequests is a modern and simple  REST library for Swift and can be used on iOS, iPadOS, macOS, tvOS, and watchOS.

This Package allows you to send REST requests extremely easily using HTTP/1.1 or HTTP/2. Thanks to Swift 4's Codable support JSON Response and Request objects are fully type validated.

The optional `RestOption` object supports the setting of specific HTTP headers, query parameters and HTTP timeout for each REST request.  

The Package is using HTTP client transport that uses the `URLSession` type from the `Foundation` framework to perform HTTP operations. It is fully secure as it is using Apple Transport Security (ATS).

It does fit best for  projects that do not want to reinvent the wheel and use a simple, small REST implementation. 

And as it is so easy to understand it easy to improve and extend!!!  

## Features

- [x] Easily perform asynchronous REST networking calls (GET, POST, PUT, PATCH, or DELETE) that send JSON
- [x] Easy API that uses Swift's async/await syntax
- [x] Natively integrates with Swift's Decodable and Encodable types
- [x] HTTP response validation
- [x] Send custom HTTP headers
- [x] Change timeout options
- [x] Fully native Swift API
- [x] Identity Pinning on CA or Leaf level using ATS

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

## Certificate pinning

You might not know but Apple introduced native support for SSL public key pinning in iOS 14. 

If you are not familiar with this native capability I recommend reading Apple’s article [Identity Pinning: How to configure server certificates for your app](https://developer.apple.com/news/?id=g9ejcf8y). Here is a summary:

- You can specify a collection of certificates in your Info.plist that App Transport Security (ATS) expects when connecting to named domains.
- A pinned CA public key must appear in either an intermediate or root certificate in a certificate chain
- Pinned keys are always associated with a domain name, and the app will refuse to connect to that domain unless the pinning requirement is met.
- You can associate multiple public keys with a domain name.

This built-in pinning works well for `URLSession` and therfore as well for SwiftRestRequests. Use it if needed!

### Prefere to use API calls for pinning

However if you prefere API calls for pinning you find `CertificateCAPinning` and `PublicKeyServerPinning` delegates for the `HttpSessionb` in the security extension.


## Write a REST Client API

 A best practice to write REST API clients is to subclass `RestApiCaller` and implement a method for each of your REST service endpoints. These speciofic implementation methods should delegate to  the generic `get, post, put, delete or put` methods of the `RestApiCaller`super class. 
 
 The request and response types used for each REST client method MUST implement the `Encodable` or `Decodable` protocol. You do normally define request and response structs using some general business model objects. These model objects implement the `Codeable` protocol so they can be used in both response or request types. 
 

### Map REST endpoints to API client methods

Each endpoint of your REST API should be mapped to a different implementation method.  The implementation method always return

-   A **Tuple** ` -> (responstObject: T?, httpStatus: Int)`: When your REST endpoint can return data in it's response body. Note: Deserializtaion to Type `T` takes place only when HTTP status `200` is returned. All other HTTP response status codes will return `nil` for the response object.

-  or an **Integer**` -> Int`: When your REST endpoint does not return data in it's response body - only HTTP status is returned.

Each REST client method  MUST declare a `throw`. As for non `2xx` HTTP response status codes a `RestError` is thrown. That error contains the HTTP response status code and an optional JSON error object. The error JSON object is deserialized from the response body with the error `Deserializer`assigned to the API caller. When no error deserializer is assigned the raw String from the response body is returned (or `nil` if there isn't one) .


### Define method for a GET endpoint with Response
```
class ClientApi: RestApiCaller {
    func myGetMethod() async throws -> (HttpBinResponse?, Int) {
        try await self.get(HttpBinResponse.self, at: "get")
    }
}
```
### Define method for a GET endpoint without Response
```
extension ClientApi {
    func myStatusGetMethod() async throws -> (Int) {
        try await self.get(at: "status/204")
    }
}
```
### API Client usage
```
let url =  URL(string: "https://httpbin.org")!
let client = ClientApi(baseUrl: url)

Task {
    
    do {
        
        let (response , httpStatus) = try await client.myGetMethod()
        
        print("HttpStatus: \(httpStatus)")
        
        if let response {
            print("Url: \(String(describing: response.url))")
            print("Origin: \(String(describing: response.origin))")
            print("Accept header: \(String(describing: response.headers.accept))")
        } else {
            print("No response")
        }
        
    } catch RestError.failedRestCall(let httpResponse, let httpStatus, let error) {
       
        print("REST service Failed with status: \(httpStatus)")
        print("Got response: \(httpResponse)")
        print("Got error: \(String(describing: error))")
       
    }
        
}
```

## Usage of RestAPICaller 


#### Making a GET Request and getting back a Response object

```
struct HttpBinHeaders: Decodable {
    let accept: String
    
    enum CodingKeys: String, CodingKey {
        case accept = "Accept"
    }
}

struct HttpBinResponse: Decodable {
    let url: String
    let origin: String
    let headers: HttpBinHeaders
}

let (response , httpStatus) = try await apiCaller.get(HttpBinResponse.self, at: "get")
    
print("HttpStatus: \(httpStatus)")
print("Url: \(String(describing: response?.url))")

```
#### Making a POST Request using a Swift 4 Encodable Request object and getting back a Decodable Response object


```

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




