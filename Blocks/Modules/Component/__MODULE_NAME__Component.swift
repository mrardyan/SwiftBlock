import SwiftUI

/// Reusable UI component view block for __MODULE_NAME__.
public struct __MODULE_NAME__Component: View {
    /// Component title text.
    public var title: String

    /// Initializes a new reusable UI component instance.
    public init(title: String = "__MODULE_NAME__ Component") {
        self.title = title
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    __MODULE_NAME__Component(title: "Sample __MODULE_NAME__")
}

