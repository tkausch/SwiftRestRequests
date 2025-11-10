# Working with Interceptors

Learn how to use and create custom interceptors in SwiftRestRequests.

## Overview

Interceptors provide a powerful way to modify requests and responses in SwiftRestRequests. They can be used for logging, authentication, request modification, and response processing.

## Built-in Interceptors

### LogNetworkInterceptor

The ``LogNetworkInterceptor`` provides detailed logging of network requests and responses:

```swift
let api = RestApiCaller()
api.addInterceptor(LogNetworkInterceptor())
```

### AuthorizerInterceptor

The ``AuthorizerInterceptor`` handles request authentication:

```swift
let authorizer = BearerTokenAuthorizer(token: "your-token")
let interceptor = AuthorizerInterceptor(authorizer: authorizer)
api.addInterceptor(interceptor)
```

## Creating Custom Interceptors

### Basic Interceptor

```swift
class TimestampInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) throws -> URLRequest {
        var request = request
        request.setValue(ISO8601DateFormatter().string(from: Date()),
                        forHTTPHeaderField: "X-Timestamp")
        return request
    }
}

// Usage
let api = RestApiCaller()
api.addInterceptor(TimestampInterceptor())
```

### Response Interceptor

```swift
class MetricsInterceptor: ResponseInterceptor {
    func intercept(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        let metrics = [
            "status_code": httpResponse.statusCode,
            "response_time": // Calculate response time
            "content_length": data.count
        ]
        
        // Log or process metrics
    }
}
```

### Chaining Interceptors

Interceptors are executed in the order they are added:

```swift
let api = RestApiCaller()
api.addInterceptor(LogNetworkInterceptor())
api.addInterceptor(AuthorizerInterceptor(authorizer: myAuthorizer))
api.addInterceptor(MetricsInterceptor())
```

## Best Practices

### Error Handling

```swift
class ValidationInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) throws -> URLRequest {
        guard let url = request.url else {
            throw RestError.invalidURL
        }
        
        // Perform validation
        guard isValid(url) else {
            throw CustomError.invalidEndpoint
        }
        
        return request
    }
}
```

### Thread Safety

```swift
class ThreadSafeInterceptor: RequestInterceptor {
    private let queue = DispatchQueue(label: "com.example.interceptor")
    private var cachedData: [String: Any] = [:]
    
    func intercept(_ request: URLRequest) throws -> URLRequest {
        return queue.sync {
            // Thread-safe operations
            var request = request
            // Modify request
            return request
        }
    }
}
```

## Topics

### Built-in Interceptors
- ``LogNetworkInterceptor``
- ``AuthorizerInterceptor``

### Protocols
- ``RequestInterceptor``
- ``ResponseInterceptor``

### Related Types
- ``RestApiCaller``
- ``RestOptions``
- ``URLRequestAuthorizer``