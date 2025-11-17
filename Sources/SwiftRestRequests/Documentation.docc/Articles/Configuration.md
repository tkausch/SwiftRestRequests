# Configuring REST Requests

Learn how to configure REST requests using RestOptions.

## Overview

``RestOptions`` provides a flexible way to customize REST API requests in SwiftRestRequests.

## Common Configurations

### Basic Options

```swift
var options = RestOptions()

// Set timeout interval
options.timeoutInterval = 30

// Add custom headers
options.headers = [
    "Authorization": "Bearer token",
    "Api-Version": "2.0"
]

// Configure expected status codes
options.expectedStatusCodes = [200, 201, 204]

let api = RestApiCaller(options: options)
```

### Query Parameters

```swift
var options = RestOptions()
options.queryParameters = [
    "page": "1",
    "limit": "10",
    "sort": "desc"
]

// Results in URL: https://api.example.com/users?page=1&limit=10&sort=desc
let users: [User] = try await api.get("https://api.example.com/users",
                                    options: options)
```

### Content Types

```swift
var options = RestOptions()
options.acceptedMimeTypes = ["application/json", "application/problem+json"]
```

### Security Configuration

```swift
var options = RestOptions()

// Configure certificate pinning
let certificatePath = Bundle.main.path(forResource: "server-cert", ofType: "der")!
options.serverPinning = CertificateCAPinning(certificatePath: certificatePath)

// Configure TLS
options.tlsConfiguration = ...
```

## Advanced Usage

### Per-Request Options

```swift
let globalOptions = RestOptions()
globalOptions.headers = ["Api-Version": "2.0"]

let api = RestApiCaller(options: globalOptions)

// Override options for specific request
var requestOptions = RestOptions()
requestOptions.headers = ["Authorization": "Bearer special-token"]
requestOptions.timeoutInterval = 60

let response = try await api.post("https://api.example.com/data",
                                body: payload,
                                options: requestOptions)
```

### Combining Options

```swift
extension RestOptions {
    static func combine(_ options: RestOptions...) -> RestOptions {
        var combined = RestOptions()
        
        for option in options {
            // Merge headers
            combined.headers.merge(option.headers) { $1 }
            
            // Merge query parameters
            combined.queryParameters.merge(option.queryParameters) { $1 }
            
            // Use latest non-nil values
            if option.timeoutInterval != nil {
                combined.timeoutInterval = option.timeoutInterval
            }
            // ... handle other properties
        }
        
        return combined
    }
}

// Usage
let baseOptions = RestOptions()
let authOptions = RestOptions(headers: ["Authorization": "Bearer token"])
let customOptions = RestOptions(timeoutInterval: 30)

let combined = RestOptions.combine(baseOptions, authOptions, customOptions)
```

## Topics

### Configuration
- ``RestOptions/httpHeaders``
- ``RestOptions/queryParameters``
- ``RestOptions/requestTimeoutSeconds``
- ``RestOptions/expectedStatusCodes``
- ``RestOptions/dateDecodingStrategy``

### Related Types
- ``RestApiCaller``
- ``CertificateCAPinning``
- ``PublicKeyServerPinning``