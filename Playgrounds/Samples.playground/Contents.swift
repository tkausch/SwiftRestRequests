import Foundation
import SwiftRestRequests

//: # Write a REST API Client
//: A best practice to write REST API clients is to subclass `RestApiCaller` and implement a method for each of your REST service endpoints. These specific implementation methods should delegate to  the generic `get, post, put, delete or put` methods of the `RestApiCaller`super class.
//: ## Define Request and Response Types
//: The request and response types used for each REST client method MUST implement the `Encodable` or `Decodable` protocol. You do normally define request and response structs using some general business model objects. These model objects implement the `Codeable` protocol so they can be used in both response or request types.
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
//: ## Define Client methods
//: Each endpoint of your REST API should be mapped to a different implementation method.  The implementation method always return
//: -   A **Tuple** ` -> (responstObject: T?, httpStatus: Int)`: When your REST endpoint can return data in it's response body. Note: Deserializtaion to Type `T` takes place only when HTTP status `200` is returned. All other HTTP response status codes will return `nil` for the response object.
//: -  or an **Integer**` -> Int`: When your REST endpoint does not return data in it's response body - only HTTP status is returned.
//:
//: Each REST client method  MUST declare a `throw`. As for non `2xx` HTTP response status codes a `RestError` is thrown. That error contains the HTTP response status code and an optional JSON error object. The error JSON object is deserialized from the response body with the error `Deserializer`assigned to the API caller. When no error deserializer is assigned the raw String from the response body is returned (or `nil` if there isn't one) .
//: ### Define method for a GET endpoint with Response
class ClientApi: RestApiCaller {
    func myGetMethod() async throws -> (HttpBinResponse?, Int) {
        try await self.get(HttpBinResponse.self, at: "get")
    }
}
//: ### Define method for a GET endpoint without Response
extension ClientApi {
    func myStatusGetMethod() async throws -> (Int) {
        try await self.get(at: "status/204")
    }
}
//: ## Call Client methods
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
