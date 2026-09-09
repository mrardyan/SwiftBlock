import SwiftUI

@MainActor
public protocol __MODULE_NAME__CoordinatorProtocol: AnyObject {
    func start()
    func dismiss()
}

@MainActor
public final class __MODULE_NAME__Coordinator: ObservableObject, __MODULE_NAME__CoordinatorProtocol {
    @Published public var isPresented: Bool = false

    public init() {}

    public func start() {
        isPresented = true
    }

    public func dismiss() {
        isPresented = false
    }
}
