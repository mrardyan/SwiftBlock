import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

@available(iOS 17.0, macOS 14.0, *)
final class __MODULE_NAME__Tests: XCTestCase {
    func testInMemoryContainerIsEmpty() throws {
        let store = __MODULE_NAME__(isStoredInMemoryOnly: true)
        let items = try store.context.fetch(FetchDescriptor<__MODULE_NAME__Item>())
        XCTAssertTrue(items.isEmpty)
    }

    func testInsertAndFetch() throws {
        let store = __MODULE_NAME__(isStoredInMemoryOnly: true)
        let context = store.context
        context.insert(__MODULE_NAME__Item(title: "First"))
        try context.save()

        let items = try context.fetch(FetchDescriptor<__MODULE_NAME__Item>())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "First")
    }
}