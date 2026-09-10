import SwiftUI

/// Navigation flow coordinator interface for `__MODULE_NAME__`.
@MainActor
public protocol __MODULE_NAME__Coordinator: AnyObject {
    func start()
    func dismiss()
}

/// Default coordinator managing navigation state for `__MODULE_NAME__`.
@MainActor
public final class Default__MODULE_NAME__Coordinator: ObservableObject, __MODULE_NAME__Coordinator {
    @Published public var isPresented: Bool = false

    public init() {}

    public func start() {
        isPresented = true
    }

    public func dismiss() {
        isPresented = false
    }
}
