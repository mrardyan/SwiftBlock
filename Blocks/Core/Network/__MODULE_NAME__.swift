import Foundation

/// Errors that can occur during network operations.
public enum NetworkError: Error, LocalizedError, Equatable {
    case invalidResponse(statusCode: Int, data: Data?)
    case decodingFailed(String)
    case transportError(String)

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

/// Interface for executing HTTP network requests and decoding responses.
public protocol Networking {
    func send<T: Decodable>(_ request: HTTPRequest) async throws -> T
}

/// HTTP network client engine.
@available(iOS 15.0, macOS 12.0, *)
public final class __MODULE_NAME__: Networking {
    private let transport: HTTPTransporting
    private let jsonDecoder: JSONDecoder

    public init(
        transport: HTTPTransporting = URLSessionTransport(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.transport = transport
        self.jsonDecoder = jsonDecoder
    }

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
