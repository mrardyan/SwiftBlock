import Foundation

/// HTTP request method verbs.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// An HTTP request configuration containing target URL, headers, and body.
public struct HTTPRequest: Sendable {
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
        if let newItems = queryItems, !newItems.isEmpty {
            let existingItems = urlComponents?.queryItems ?? []
            urlComponents?.queryItems = existingItems + newItems
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
public protocol HTTPTransporting: Sendable {
    func send(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse)
}

/// `URLSession`-backed HTTP transport layer.
public final class URLSessionTransport: HTTPTransporting, Sendable {
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
