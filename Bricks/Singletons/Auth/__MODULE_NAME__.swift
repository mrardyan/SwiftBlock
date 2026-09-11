import Foundation

/// Authentication state of a user session.
public enum SessionState: Equatable {
    case unauthenticated
    case authenticated(userId: String)
}

/// A delegate that receives session state changes.
public protocol SessionDelegate: AnyObject {
    func sessionStateDidChange(_ state: SessionState)
}

/// Interface for managing user authentication state and session tokens.
public protocol Authenticatable {
    var currentState: SessionState { get }
    var accessToken: String? { get }
    func setSession(accessToken: String, userId: String)
    func clearSession()
}

/// In-memory user session state manager.
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
