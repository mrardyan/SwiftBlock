import SwiftUI

public enum AppRoute: Hashable {
    // MARK: - SwiftBlock Route Enum Marker
    case home
}

public final class AppCoordinator: ObservableObject {
    @Published public var path: [AppRoute] = []

    public init() {}

    @ViewBuilder
    public func buildView(for route: AppRoute) -> some View {
        switch route {
        // MARK: - SwiftBlock Route View Marker
        case .home:
            Text("Home")
        }
    }
}
