import Foundation

/// Represents user authentication session states.
public enum SessionState: Equatable {
    case unauthenticated
    case authenticated(userId: String)
}

/// Delegate protocol to observe authentication state transitions.
public protocol SessionDelegate: AnyObject {
    /// Triggered when the user session state changes.
    func sessionStateDidChange(_ state: SessionState)
}

/// Protocol defining authentication management capabilities.
public protocol Authenticatable {
    /// Current session state of the user.
    var currentState: SessionState { get }

    /// Active access token if authenticated.
    var accessToken: String? { get }

    /// Sets active user authentication session tokens.
    func setSession(accessToken: String, userId: String)

    /// Clears active user session state and tokens.
    func clearSession()
}

/// Implementation managing user authentication state and access tokens.
public final class __MODULE_NAME__: Authenticatable {
    /// Current authentication state of the session manager.
    public private(set) var currentState: SessionState = .unauthenticated

    /// Current active access token.
    public private(set) var accessToken: String?

    /// Optional delegate listener for session state changes.
    public weak var delegate: SessionDelegate?

    /// Initializes a new session manager instance.
    public init() {}

    /// Sets session tokens and notifies delegate of authentication state change.
    public func setSession(accessToken: String, userId: String) {
        self.accessToken = accessToken
        self.currentState = .authenticated(userId: userId)
        delegate?.sessionStateDidChange(currentState)
    }

    /// Clears session tokens and updates state to unauthenticated.
    public func clearSession() {
        self.accessToken = nil
        self.currentState = .unauthenticated
        delegate?.sessionStateDidChange(.unauthenticated)
    }
}

