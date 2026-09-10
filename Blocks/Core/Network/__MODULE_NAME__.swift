import Foundation

/// Errors that can occur during network operations.
public enum NetworkError: Error, LocalizedError, Equatable {
    case invalidResponse(statusCode: Int, data: Data?)
    case decodingFailed(String)
    case transportError(String)

    /// Human-readable error description.
    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let code, _):
            return "Server responded with status code \(code)."
        case .decodingFailed(let reason):
            return "Failed to decode response: \(reason)."
        case .transportError(let message):
            return "Network transport error: \(message)."
        }
    }
}

/// Interface for sending HTTP network requests and decoding responses.
public protocol Networking {
    /// Sends a request and decodes the response into the specified Decodable type.
    func send<T: Decodable>(_ request: HTTPRequest) async throws -> T
}

/// HTTP network client implementation.
public final class __MODULE_NAME__: Networking {
    private let transport: HTTPTransporting
    private let jsonDecoder: JSONDecoder

    /// Initializes a new network client instance.
    /// - Parameters:
    ///   - transport: HTTP transport engine (defaults to URLSessionTransport).
    ///   - jsonDecoder: JSON decoder instance for response parsing.
    public init(
        transport: HTTPTransporting = URLSessionTransport(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.transport = transport
        self.jsonDecoder = jsonDecoder
    }

    /// Sends an HTTP request asynchronously and decodes the payload.
    public func send<T: Decodable>(_ request: HTTPRequest) async throws -> T {
        let (data, response) = try await transport.send(request)

        guard (200...299).contains(response.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: response.statusCode, data: data)
        }

        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
}
