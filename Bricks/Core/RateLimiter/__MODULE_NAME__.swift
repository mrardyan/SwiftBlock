#if canImport(Vapor)
import Vapor

/// In-memory fixed-window rate limiting middleware keyed by remote address.
public final class __MODULE_NAME__: Middleware, @unchecked Sendable {
    private struct Window {
        var count: Int
        var resetAt: Date
    }

    private let maxRequests: Int
    private let windowDuration: TimeInterval
    private let maxTrackedClients: Int
    private var windows: [String: Window] = [:]
    private let lock = NSLock()

    public init(maxRequests: Int = 60, windowDuration: TimeInterval = 60, maxTrackedClients: Int = 10_000) {
        self.maxRequests = maxRequests
        self.windowDuration = windowDuration
        self.maxTrackedClients = maxTrackedClients
    }

    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let key = request.remoteAddress?.description ?? "unknown"
        let now = Date()

        lock.lock()
        if windows.count >= maxTrackedClients {
            windows = windows.filter { $0.value.resetAt > now }
        }
        var entry = windows[key]
        if entry == nil || now >= (entry?.resetAt ?? now) {
            entry = Window(count: 0, resetAt: now.addingTimeInterval(windowDuration))
        }
        entry?.count += 1
        windows[key] = entry
        let allowed = (entry?.count ?? 0) <= maxRequests
        lock.unlock()

        guard allowed else {
            return request.eventLoop.makeFailedFuture(
                Abort(.tooManyRequests, reason: "Rate limit exceeded. Please try again later.")
            )
        }
        return next.respond(to: request)
    }
}
#endif