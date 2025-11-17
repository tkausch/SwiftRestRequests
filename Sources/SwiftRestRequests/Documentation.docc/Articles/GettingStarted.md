# Getting Started

Follow these steps to integrate ``SwiftRestRequests`` into a Swift Package or Xcode project and perform your
first request.

## Add the package dependency

Use Swift Package Manager to depend on the library:

```swift
.package(url: "https://github.com/tkausch/SwiftRestRequests", from: "1.6.3")
```

Then add ``SwiftRestRequests`` to your target dependencies. Xcode users can add the package through
**File → Add Packages…** with the same URL.

## Configure a client

Subclass ``RestApiCaller`` (or instantiate it directly) to describe your REST API in a strongly typed way:

```swift
import SwiftRestRequests

final class HttpBinClient: RestApiCaller {
    func status204() async throws -> Int {
        try await get(at: "status/204")
    }

    func getEcho() async throws -> (HttpBinResponse?, Int) {
        try await get(HttpBinResponse.self, at: "get")
    }
}

struct HttpBinResponse: Decodable {
    let url: String
    let origin: String
}

let client = HttpBinClient(baseUrl: URL(string: "https://httpbin.org")!)
let (response, status) = try await client.getEcho()
```

`RestApiCaller` automatically applies default headers, validates the HTTP status, decodes JSON payloads
with ``DecodableDeserializer``, and throws ``RestError`` when something goes wrong.

## Customize each request

``RestOptions`` lets you override headers, query parameters, or status expectations without reconfiguring
your client:

```swift
var options = RestOptions()
options.httpHeaders = ["X-Test": "demo"]
options.expectedStatusCodes = [200, 204]

let status = try await client.delete(at: "resource/42", options: options)
```

Use `headerGenerator` or register a ``URLRequestInterceptor`` subclass to insert shared headers, log
traffic, inject authentication, or perform response inspection:

```swift
client.registerRequestInterceptor(LogNetworkInterceptor(enableNetworkTracing: true))
```

## Handle errors

All failures surface as ``RestError``. Switch over the cases to provide better feedback or retry logic:

```swift
catch let error as RestError {
    switch error {
    case .invalidMimeType(let mime):
        print("Unexpected MIME type: \(mime ?? "none")")
    case .failedRestCall(_, let status, let payload):
        print("Server rejected the call with status \(status). Payload: \(String(describing: payload))")
    default:
        print("Unhandled REST error: \(error)")
    }
}
```
