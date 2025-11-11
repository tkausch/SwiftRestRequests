# Error Handling Guide

Learn how to handle errors effectively in SwiftRestRequests.

## Overview

SwiftRestRequests provides comprehensive error handling through the ``RestError`` type. This guide explains common error scenarios and how to handle them effectively.

## Common Error Types

### Network Errors

```swift
do {
    let response = try await api.get("https://api.example.com/data")
} catch RestError.badResponse(let response, let data) {
    print("Invalid response: \(response)")
    // Handle invalid response format
} catch RestError.networkError(let error) {
    // Handle network connectivity issues
    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet:
            // Handle no internet connection
        case .timedOut:
            // Handle request timeout
        default:
            // Handle other network errors
        }
    }
}
```

### Data Processing Errors

```swift
do {
    let item: Item = try await api.get("https://api.example.com/items/1")
} catch RestError.malformedResponse(let response, let data, let error) {
    if let decodingError = error as? DecodingError {
        switch decodingError {
        case .keyNotFound(let key, _):
            print("Missing required field: \(key)")
        case .typeMismatch(_, let context):
            print("Invalid data type at: \(context.codingPath)")
        default:
            print("Other decoding error: \(decodingError)")
        }
    }
}
```

### API Errors

```swift
do {
    let response = try await api.post("https://api.example.com/items", body: newItem)
} catch RestError.failedRestCall(let response, let status, let error) {
    switch status {
    case .unauthorized:
        // Handle authentication failure
    case .notFound:
        // Handle resource not found
    case .tooManyRequests:
        // Handle rate limiting
    default:
        // Handle other API errors
    }
}
```

## Error Recovery Strategies

### Retry Logic

```swift
func retryableRequest<T: Decodable>(maxAttempts: Int = 3) async throws -> T {
    var attempts = 0
    
    while attempts < maxAttempts {
        do {
            return try await api.get("https://api.example.com/data")
        } catch RestError.networkError(let error) {
            attempts += 1
            if attempts == maxAttempts { throw error }
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempts))) * 1_000_000_000)
        }
    }
    
    throw RestError.networkError(NSError(domain: "", code: -1))
}
```

### Graceful Degradation

```swift
func fetchUserData() async throws -> User {
    do {
        // Try to fetch full user data
        return try await api.get("https://api.example.com/users/1")
    } catch RestError.failedRestCall(_, .notFound, _) {
        // Fall back to cached data
        return try await getCachedUser()
    } catch RestError.networkError {
        // Fall back to offline mode
        return try await getOfflineUser()
    }
}
```

## Best Practices

### Custom Error Handling

```swift
extension RestError {
    var isRetryable: Bool {
        switch self {
        case .networkError(let error):
            return (error as? URLError)?.code != .cancelled
        case .failedRestCall(_, let status, _):
            return status.rawValue >= 500
        default:
            return false
        }
    }
}
```

### Error Logging

```swift
class ErrorLogger {
    static func log(_ error: RestError) {
        switch error {
        case .malformedResponse(let response, let data, let error):
            print("""
                Failed to process response:
                URL: \(response.url?.absoluteString ?? "unknown")
                Status: \(response.statusCode)
                Error: \(error)
                Data: \(String(data: data, encoding: .utf8) ?? "invalid data")
                """)
        // Handle other cases...
        }
    }
}
```

## Topics

### Error Types
- ``RestError``
- ``HTTPStatusCode``

### Related
- ``RestApiCaller``
- ``RestOptions``
- ``LogNetworkInterceptor``