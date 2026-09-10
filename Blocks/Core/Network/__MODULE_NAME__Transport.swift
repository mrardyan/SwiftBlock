import Foundation

/// HTTP request methods supported by the transport layer.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Encapsulates HTTP request configuration including URL, method, headers, query items, and body payload.
public struct HTTPRequest {
    /// Target request URL.
    public var url: URL

    /// HTTP method verb.
    public var method: HTTPMethod

    /// HTTP request headers.
    public var headers: [String: String]

    /// Optional query parameters appended to the URL.
    public var queryItems: [URLQueryItem]?

    /// Optional binary body payload.
    public var body: Data?

    /// Initializes a new HTTP request specification.
    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = ["Content-Type": "application/json"],
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }

    /// Constructs a standard Foundation URLRequest from this request instance.
    public func buildURLRequest() -> URLRequest {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryItems = queryItems, !queryItems.isEmpty {
            urlComponents?.queryItems = queryItems
        }

        let finalURL = urlComponents?.url ?? url
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}

/// Low-level HTTP transport protocol.
public protocol HTTPTransporting {
    /// Sends an HTTP request and returns raw Data along with HTTPURLResponse.
    func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse)
}

/// Standard URLSession implementation of HTTPTransporting.
public final class URLSessionTransport: HTTPTransporting {
    private let session: URLSession

    /// Initializes transport with a specific URLSession instance (defaults to .shared).
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Sends request over URLSession asynchronously.
    public func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = request.buildURLRequest()
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.cannotParseResponse)
        }

        return (data, httpResponse)
    }
}
