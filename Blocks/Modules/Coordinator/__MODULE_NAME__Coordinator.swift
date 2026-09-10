import SwiftUI

/// Navigation flow coordinator interface for __MODULE_NAME__.
@MainActor
public protocol __MODULE_NAME__Coordinator: AnyObject {
    /// Starts the navigation flow.
    func start()

    /// Dismisses the navigation flow.
    func dismiss()
}

/// Default navigation coordinator implementation for __MODULE_NAME__.
@MainActor
public final class Default__MODULE_NAME__Coordinator: ObservableObject, __MODULE_NAME__Coordinator {
    /// Presentation state flag controlling view visibility.
    @Published public var isPresented: Bool = false

    /// Initializes a new coordinator instance.
    public init() {}

    /// Presents the flow by updating presentation state.
    public func start() {
        isPresented = true
    }

    /// Dismisses the flow by resetting presentation state.
    public func dismiss() {
        isPresented = false
    }
}

