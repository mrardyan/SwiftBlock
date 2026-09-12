import SwiftUI

public final class DependencyContainer {
    public static let shared = DependencyContainer()
    private var factories: [String: () -> Any] = [:]

    public init() {
        setupDependencies()
    }

    public func setupDependencies() {
        // MARK: - SwiftBlock Dependency Injection Marker
    }

    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[String(describing: type)] = factory
    }

    public func resolve<T>(_ type: T.Type = T.self) -> T {
        guard let factory = factories[String(describing: type)], let instance = factory() as? T else {
            fatalError("No registered dependency for \(type)")
        }
        return instance
    }
}
