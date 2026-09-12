import Foundation

/// Application lifecycle states.
public enum AppLifecycleState: Sendable, Equatable, Hashable {
    case active
    case inactive
    case background
}

/// Protocol for application lifecycle state monitoring.
public protocol AppStateProtocol: Sendable {
    var currentState: AppLifecycleState { get }
    var isActive: Bool { get }
    var isBackground: Bool { get }
}

/// Thread-safe observer for application lifecycle changes.
public final class __MODULE_NAME__: @unchecked Sendable, AppStateProtocol {
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private var _currentState: AppLifecycleState

    public var currentState: AppLifecycleState {
        lock.lock()
        defer { lock.unlock() }
        return _currentState
    }

    public var isActive: Bool { currentState == .active }
    public var isBackground: Bool { currentState == .background }

    public init(initialState: AppLifecycleState = .active) {
        self._currentState = initialState
    }

    /// Update current application state (e.g. from AppDelegate or SceneDelegate).
    public func transitionTo(_ newState: AppLifecycleState) {
        lock.lock()
        defer { lock.unlock() }
        _currentState = newState
    }
}
