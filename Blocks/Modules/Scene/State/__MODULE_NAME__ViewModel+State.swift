import Foundation

extension __MODULE_NAME__ViewModel {
    /// State properties rendered by __MODULE_NAME__View.
    struct State {
        /// Screen title text.
        var title: String = "__MODULE_NAME__"

        /// Loading activity indicator flag.
        var isLoading: Bool = false
    }

    /// User and system actions supported by __MODULE_NAME__ViewModel.
    enum Action {
        case onAppear
    }
}
