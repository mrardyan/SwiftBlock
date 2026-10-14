import Foundation

/// Protocol abstraction for thread-safe dependency injection registry.
public protocol DependencyContainerProtocol: Sendable {
    func register<T: Sendable>(_ type: T.Type, factory: @Sendable @escaping () -> T) async
    func registerSingleton<T: Sendable>(_ type: T.Type, instance: T) async
    func resolve<T: Sendable>(_ type: T.Type) async -> T?
    func reset() async
}

/// Actor-isolated, thread-safe dependency injection container.
public actor AppDependencyContainer: DependencyContainerProtocol {
    public static let shared = AppDependencyContainer()

    private var factories: [String: @Sendable () -> Any] = [:]
    private var singletons: [String: Any] = [:]

    public init() {}

    private func makeKey<T>(for type: T.Type) -> String {
        String(reflecting: type)
    }

    /// Registers a transient factory provider.
    public func register<T: Sendable>(_ type: T.Type, factory: @Sendable @escaping () -> T) {
        let key = makeKey(for: type)
        factories[key] = factory
    }

    /// Registers an existing singleton instance.
    public func registerSingleton<T: Sendable>(_ type: T.Type, instance: T) {
        let key = makeKey(for: type)
        singletons[key] = instance
    }

    /// Resolves an instance of type `T`.
    public func resolve<T: Sendable>(_ type: T.Type) -> T? {
        let key = makeKey(for: type)
        if let existing = singletons[key] as? T {
            return existing
        }
        if let factory = factories[key], let created = factory() as? T {
            return created
        }
        return nil
    }

    /// Clears all registered instances and factories (useful for unit testing).
    public func reset() {
        factories.removeAll()
        singletons.removeAll()
    }
}

// MARK: - Synchronous Resolution Bridge & Property Wrapper

/// Unfair-lock protected bridge for synchronous dependency resolution.
public final class SyncDependencyResolver: @unchecked Sendable {
    public static let shared = SyncDependencyResolver()
    private let lock = NSLock()
    private var syncSingletons: [String: Any] = [:]

    private init() {}

    public func register<T>(_ type: T.Type, instance: T) {
        lock.lock()
        defer { lock.unlock() }
        syncSingletons[String(reflecting: type)] = instance
    }

    public func resolve<T>(_ type: T.Type) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return syncSingletons[String(reflecting: type)] as? T
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        syncSingletons.removeAll()
    }
}

/// Declarative property wrapper to resolve dependencies cleanly in Views & ViewModels.
@propertyWrapper
public struct Injected<T> {
    private var instance: T?

    public init() {}

    public var wrappedValue: T {
        mutating get {
            if let cached = instance { return cached }
            guard let resolved = SyncDependencyResolver.shared.resolve(T.self) else {
                fatalError("[Injected] Failed to resolve dependency for type \(T.self). Ensure it is registered in SyncDependencyResolver.")
            }
            self.instance = resolved
            return resolved
        }
    }
}
