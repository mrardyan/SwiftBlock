import Foundation
import SwiftUI

/// ViewModel managing state and simulated data fetching for `__MODULE_NAME__`.
@MainActor
public final class __MODULE_NAME__ViewModel: ObservableObject {
    @Published public private(set) var state: State
    private let delayDuration: TimeInterval

    /// Initializes ViewModel with optional state and configurable simulated network delay (in seconds).
    public init(state: State = State(), delayDuration: TimeInterval = 1.0) {
        self.state = state
        self.delayDuration = delayDuration
    }

    /// Primary action handler for user and system events.
    public func handle(_ action: Action) async {
        switch action {
        case .onAppear, .loadData, .refresh:
            await fetchSimulatedData()
        }
    }

    /// Simulates asynchronous API fetch with configurable delay and finite state transitions.
    private func fetchSimulatedData() async {
        state.status = .loading

        if delayDuration > 0 {
            let nanoseconds = UInt64(delayDuration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
        }

        // Mock data fetch result
        let mockItems = [
            "__MODULE_NAME__ Item 1",
            "__MODULE_NAME__ Item 2",
            "__MODULE_NAME__ Item 3"
        ]

        if mockItems.isEmpty {
            state.status = .empty
        } else {
            state.status = .loaded(items: mockItems)
        }
    }
}
