import Foundation
import SwiftData

/// Sample persistable model managed by the SwiftData stack.
@available(iOS 17.0, macOS 14.0, *)
@Model
public final class __MODULE_NAME__Item {
    public var id: UUID
    public var title: String
    public var createdAt: Date

    public init(id: UUID = UUID(), title: String, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}

/// Central SwiftData stack providing the shared `ModelContainer` and `ModelContext`.
@available(iOS 17.0, macOS 14.0, *)
public final class __MODULE_NAME__ {
    public static let shared = __MODULE_NAME__()

    public let container: ModelContainer

    public init(isStoredInMemoryOnly: Bool = false) {
        let schema = Schema([__MODULE_NAME__Item.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
        do {
            self.container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    public var context: ModelContext {
        return container.mainContext
    }
}