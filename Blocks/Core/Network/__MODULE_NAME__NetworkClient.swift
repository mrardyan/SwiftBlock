import Foundation

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

public protocol __MODULE_NAME__NetworkClientProtocol {
    func send<T: Decodable>(_ request: HTTPRequest) async throws -> T
}

public final class __MODULE_NAME__NetworkClient: __MODULE_NAME__NetworkClientProtocol {
    private let transport: HTTPTransportProtocol
    private let jsonDecoder: JSONDecoder

    public init(
        transport: HTTPTransportProtocol = URLSessionTransport(),
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
