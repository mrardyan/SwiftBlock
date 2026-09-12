import Foundation

extension __MODULE_NAME__ViewModel {
    /// Finite state rendering options for `__MODULE_NAME__View`.
    public enum ViewStatus: Equatable, Sendable {
        case idle
        case loading
        case loaded(items: [String])
        case empty
        case error(message: String)
    }

    /// Overall state properties rendered by `__MODULE_NAME__View`.
    public struct State: Equatable, Sendable {
        public var title: String
        public var status: ViewStatus

        public init(title: String = "__MODULE_NAME__", status: ViewStatus = .idle) {
            self.title = title
            self.status = status
        }

        public var isLoading: Bool {
            status == .loading
        }

        public var errorMessage: String? {
            if case .error(let message) = status { return message }
            return nil
        }
    }

    /// User and system actions supported by `__MODULE_NAME__ViewModel`.
    public enum Action: Sendable {
        case onAppear
        case loadData
        case refresh
    }
}
