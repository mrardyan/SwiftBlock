import Foundation

public enum SessionState: Equatable {
    case unauthenticated
    case authenticated(userId: String)
}

public protocol SessionDelegate: AnyObject {
    func sessionStateDidChange(_ state: SessionState)
}

public protocol Authenticatable {
    var currentState: SessionState { get }
    var accessToken: String? { get }
    func setSession(accessToken: String, userId: String)
    func clearSession()
}

public final class __MODULE_NAME__: Authenticatable {
    public private(set) var currentState: SessionState = .unauthenticated
    public private(set) var accessToken: String?

    public weak var delegate: SessionDelegate?

    public init() {}

    public func setSession(accessToken: String, userId: String) {
        self.accessToken = accessToken
        self.currentState = .authenticated(userId: userId)
        delegate?.sessionStateDidChange(currentState)
    }

    public func clearSession() {
        self.accessToken = nil
        self.currentState = .unauthenticated
        delegate?.sessionStateDidChange(.unauthenticated)
    }
}
