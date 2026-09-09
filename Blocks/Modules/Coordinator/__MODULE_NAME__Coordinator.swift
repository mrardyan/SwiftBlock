import SwiftUI

@MainActor
public protocol __MODULE_NAME__Coordinator: AnyObject {
    func start()
    func dismiss()
}

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
