import Foundation

public protocol AnalyticsEventProtocol {
    var name: String { get }
    var parameters: [String: Any]? { get }
}

public struct AnalyticsEvent: AnalyticsEventProtocol {
    public let name: String
    public let parameters: [String: Any]?

    public init(name: String, parameters: [String: Any]? = nil) {
        self.name = name
        self.parameters = parameters
    }
}
