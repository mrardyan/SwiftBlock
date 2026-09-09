import SwiftUI

@MainActor
final class __MODULE_NAME__ViewModel: ObservableObject {
    @Published var state: State

    init(state: State = State()) {
        self.state = state
    }

    func send(_ action: Action) {
        switch action {
        case .onAppear:
            break
        }
    }
}
