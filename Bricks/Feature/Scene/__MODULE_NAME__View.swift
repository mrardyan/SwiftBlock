import SwiftUI

/// SwiftUI view for `__MODULE_NAME__` with finite state rendering.
public struct __MODULE_NAME__View: View {
    @StateObject private var viewModel: __MODULE_NAME__ViewModel

    @MainActor
    public init(viewModel: __MODULE_NAME__ViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? __MODULE_NAME__ViewModel())
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(viewModel.state.title)
                .font(.title)
                .fontWeight(.bold)

            switch viewModel.state.status {
            case .idle:
                Color.clear
                    .onAppear {
                        Task {
                            await viewModel.handle(.onAppear)
                        }
                    }

            case .loading:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading \(viewModel.state.title)...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let items):
                List(items, id: \.self) { item in
                    Text(item)
                }
                .refreshable {
                    await viewModel.handle(.refresh)
                }

            case .empty:
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Items Available")
                        .font(.headline)
                    Button("Reload") {
                        Task {
                            await viewModel.handle(.loadData)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .error(let message):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await viewModel.handle(.loadData)
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}

#Preview {
    __MODULE_NAME__View()
}
