# ``SwiftRestRequests``

SwiftRestRequests is an async/await-first HTTP client powered by `URLSession`. It focuses on strong typing,
first-class logging, and convenient extensibility points so you can build reliable REST integrations with
minimum boilerplate.

## Overview

SwiftRestRequests extends `URLSession` with conveniences that are typically reimplemented in every codebase:

- Common HTTP verbs that automatically encode `Encodable` requests and decode `Decodable` responses.
- Unified error handling via ``RestError`` so you can differentiate validation problems from server-side
  failures.
- Request- and response-level interception through ``URLRequestInterceptor`` and header generators.
- Built-in helpers for authentication (`BasicRequestAuthorizer`, `BearerReqeustAuthorizer`, and
  ``URLRequestAuthorizer``) plus optional TLS pinning utilities.
- Structured logging via `swift-log`, making it easy to plug in OSLog or server-side log drains.

The package supports iOS, macOS, watchOS, tvOS, visionOS, and Linux. It targets Swift 5.9 and uses
`StrictConcurrency` to ensure async code is safe by default.

## Topics

### Essentials

- <doc:GettingStarted>
- ``RestApiCaller``
- ``RestOptions``
- ``RestError``

### Authentication

- ``URLRequestAuthorizer``
- ``BasicRequestAuthorizer``
- ``BearerRequestAuthorizer``
- ``NoneAuthorizer``
- ``AuthorizerInterceptor``

### Interception and Observability

- ``URLRequestInterceptor``
- ``LogNetworkInterceptor``
- ``HeaderGenerator``

### Serialization

- ``Deserializer``
- ``DecodableDeserializer``
- ``VoidDeserializer``
- ``DataDeserializer``
