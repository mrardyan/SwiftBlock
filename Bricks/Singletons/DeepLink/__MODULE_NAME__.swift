import Foundation

/// Parsed deep link route representation.
public struct DeepLinkRoute: Equatable, Sendable {
    public let host: String
    public let pathComponents: [String]
    public let queryItems: [String: String]
    public let rawURL: URL

    public init(url: URL) {
        self.rawURL = url
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        self.host = components?.host ?? url.host ?? ""
        self.pathComponents = url.pathComponents.filter { $0 != "/" }

        var queryMap: [String: String] = [:]
        if let items = components?.queryItems {
            for item in items {
                if let val = item.value {
                    queryMap[item.name] = val
                }
            }
        }
        self.queryItems = queryMap
    }
}

/// Handler block for deep link routes.
public typealias DeepLinkHandler = @Sendable (DeepLinkRoute) -> Void

/// Defines standard interface for deep link routing.
public protocol DeepLinkRouterProtocol: Sendable {
    func registerHandler(forHost host: String, handler: @escaping DeepLinkHandler)
    func handle(_ url: URL) -> Bool
}

/// Thread-safe deep link router singleton.
public final class __MODULE_NAME__: @unchecked Sendable, DeepLinkRouterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private var handlers: [String: DeepLinkHandler] = [:]

    public init() {}

    /// Registers a route handler for a given host (e.g., "checkout", "product", "profile").
    public func registerHandler(forHost host: String, handler: @escaping DeepLinkHandler) {
        lock.lock()
        defer { lock.unlock() }
        handlers[host.lowercased()] = handler
    }

    /// Parses and dispatches a deep link URL to its registered handler.
    /// - Parameter url: The incoming deep link URL (e.g. `myapp://checkout/123?promo=SAVE10`).
    /// - Returns: `true` if a matching handler was found and executed, `false` otherwise.
    public func handle(_ url: URL) -> Bool {
        let route = DeepLinkRoute(url: url)
        let hostKey = route.host.lowercased()

        lock.lock()
        let handler = handlers[hostKey]
        lock.unlock()

        guard let handler = handler else { return false }
        handler(route)
        return true
    }
}
