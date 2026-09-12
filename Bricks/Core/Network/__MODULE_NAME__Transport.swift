import Foundation

/// HTTP request method verbs.
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// An HTTP request configuration containing target URL, headers, and body.
public struct HTTPRequest {
    public var url: URL
    public var method: HTTPMethod
    public var headers: [String: String]
    public var queryItems: [URLQueryItem]?
    public var body: Data?

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

    /// Creates a Foundation `URLRequest` configured with this request's properties.
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

/// Low-level HTTP transport interface.
public protocol HTTPTransporting {
    func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse)
}

/// `URLSession`-backed HTTP transport layer.
public final class URLSessionTransport: HTTPTransporting {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = request.buildURLRequest()
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.cannotParseResponse)
        }

        return (data, httpResponse)
    }
}
