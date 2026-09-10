import SwiftUI

/// Observable ViewModel controlling state and user actions for __MODULE_NAME__.
@MainActor
final class __MODULE_NAME__ViewModel: ObservableObject {
    /// Published View state wrapper.
    @Published var state: State

    /// Initializes ViewModel with default or custom state.
    init(state: State = State()) {
        self.state = state
    }

    /// Dispatches UI actions to update ViewModel state or execute side-effects.
    func send(_ action: Action) {
        switch action {
        case .onAppear:
            break
        }
    }
}
