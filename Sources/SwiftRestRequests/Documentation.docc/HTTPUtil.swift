extension HTTPUtil {
    /// Additional documentation for HTTPUtil
    ///
    /// ## Overview
    /// HTTPUtil provides utility functions for working with HTTP requests and responses.
    ///
    /// ## Topics
    ///
    /// ### Status Code Handling
    /// - ``isSuccessful(_:)``
    /// - ``isClientError(_:)``
    /// - ``isServerError(_:)``
    ///
    /// ### Response Validation
    /// - ``validateResponse(_:data:)``
    /// - ``validateStatusCode(_:)``
    ///
    /// ### MIME Type Handling
    /// - ``validateContentType(_:expected:)``
    /// - ``parseContentType(_:)``
    ///
    /// ### Examples
    ///
    /// #### Validating Status Codes
    /// ```swift
    /// let response = ... // HTTPURLResponse
    /// if HTTPUtil.isSuccessful(response.statusCode) {
    ///     // Process successful response
    /// } else if HTTPUtil.isClientError(response.statusCode) {
    ///     // Handle client error
    /// } else if HTTPUtil.isServerError(response.statusCode) {
    ///     // Handle server error
    /// }
    /// ```
    ///
    /// #### Content Type Validation
    /// ```swift
    /// let response = ... // HTTPURLResponse
    /// try HTTPUtil.validateContentType(response, expected: ["application/json"])
    /// ```
    public static var documentation: Never { fatalError() }
}