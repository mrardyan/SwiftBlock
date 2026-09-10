import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __PROJECT_NAME__

private struct MockTransport: HTTPTransporting {
    let mockData: Data
    let statusCode: Int

    func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: request.url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        return (mockData, response)
    }
}

final class __MODULE_NAME__Tests: XCTestCase {
    func testSuccessfulResponseDecoding() async throws {
        struct MockUser: Codable, Equatable {
            let name: String
        }

        let json = #"{"name":"John Doe"}"#.data(using: .utf8)!
        let mockTransport = MockTransport(mockData: json, statusCode: 200)
        let client = __MODULE_NAME__(transport: mockTransport)

        let request = HTTPRequest(url: URL(string: "https://api.example.com/user")!)
        let user: MockUser = try await client.send(request)

        XCTAssertEqual(user.name, "John Doe")
    }

    func testErrorResponseHandling() async {
        let mockTransport = MockTransport(mockData: Data(), statusCode: 500)
        let client = __MODULE_NAME__(transport: mockTransport)

        let request = HTTPRequest(url: URL(string: "https://api.example.com/error")!)

        do {
            let _: String = try await client.send(request)
            XCTFail("Expected NetworkError.invalidResponse but succeeded")
        } catch let NetworkError.invalidResponse(code, _) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
