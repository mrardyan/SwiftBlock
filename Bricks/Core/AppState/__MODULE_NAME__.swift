import Foundation

/// Application lifecycle states.
public enum AppLifecycleState: Sendable, Equatable, Hashable {
    case active
    case inactive
    case background
}

/// Protocol for application lifecycle state monitoring.
public protocol AppStateProtocol: Sendable {
{{#if concurrency == 'swift-concurrency'}}
    var currentState: AppLifecycleState { get async }
    var isActive: Bool { get async }
    var isBackground: Bool { get async }
    func transitionTo(_ newState: AppLifecycleState) async
{{else}}
    var currentState: AppLifecycleState { get }
    var isActive: Bool { get }
    var isBackground: Bool { get }
    func transitionTo(_ newState: AppLifecycleState)
{{/if}}
}

{{#if concurrency == 'swift-concurrency'}}
/// Actor-isolated observer for application lifecycle changes.
public actor __MODULE_NAME__: AppStateProtocol {
    public static let shared = __MODULE_NAME__()

    private var _currentState: AppLifecycleState

    public var currentState: AppLifecycleState { _currentState }
    public var isActive: Bool { _currentState == .active }
    public var isBackground: Bool { _currentState == .background }

    public init(initialState: AppLifecycleState = .active) {
        self._currentState = initialState
    }

    /// Update current application state (e.g. from AppDelegate or SceneDelegate).
    public func transitionTo(_ newState: AppLifecycleState) {
        _currentState = newState
    }
}
{{else}}
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
{{/if}}
