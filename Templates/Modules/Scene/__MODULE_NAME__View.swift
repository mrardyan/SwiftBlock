import SwiftUI

struct __MODULE_NAME__View: View {
    @StateObject var viewModel: __MODULE_NAME__ViewModel

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
