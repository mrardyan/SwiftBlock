import SwiftUI

/// SwiftUI View component for __MODULE_NAME__.
struct __MODULE_NAME__View: View {
    /// Associated ViewModel instance managing view state and actions.
    @StateObject var viewModel: __MODULE_NAME__ViewModel

    /// Initializes View with optional ViewModel dependency injection.
    init(viewModel: __MODULE_NAME__ViewModel = __MODULE_NAME__ViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            Text("__MODULE_NAME__")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    __MODULE_NAME__View()
}

