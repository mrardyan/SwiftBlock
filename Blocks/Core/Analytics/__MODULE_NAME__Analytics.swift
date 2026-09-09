import Foundation

public protocol __MODULE_NAME__AnalyticsProtocol {
    func logEvent(name: String, parameters: [String: Any]?)
}

public final class __MODULE_NAME__Analytics: __MODULE_NAME__AnalyticsProtocol {
    public init() {}

    public func logEvent(name: String, parameters: [String: Any]? = nil) {
        #if DEBUG
        print("📊 [Analytics Event] \(name) | params: \(parameters ?? [:])")
        #endif
    }
}
