import SwiftUI

/// SwiftUI form view for `__MODULE_NAME__` with per-field validation feedback.
public struct __MODULE_NAME__FormView: View {
    @StateObject private var viewModel: __MODULE_NAME__FormViewModel

    @MainActor
    public init(viewModel: __MODULE_NAME__FormViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? __MODULE_NAME__FormViewModel())
    }

    public var body: some View {
        Form {
            ForEach(viewModel.fieldNames, id: \.self) { field in
                Section(header: Text(field.capitalized)) {
                    TextField(field.capitalized, text: Binding(
                        get: { viewModel.bindingValue(for: field) },
                        set: { viewModel.update(field, value: $0) }
                    ))
                    if let error = viewModel.errors[field] {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }

            Section {
                Button {
                    Task { await viewModel.submit() }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                    } else {
                        Text("Submit")
                    }
                }
                .disabled(!viewModel.isValid || viewModel.isSubmitting)
            }
        }
    }
}

#Preview {
    __MODULE_NAME__FormView()
}