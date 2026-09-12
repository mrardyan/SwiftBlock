import XCTest
@testable import __MODULE_NAME__

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class __MODULE_NAME__Tests: XCTestCase {
    private var formatter: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        formatter = __MODULE_NAME__()
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    func testRelativeFormatting() {
        let now = Date()
        let fiveMinutesAgo = now.addingTimeInterval(-300)
        let result = formatter.localizedString(for: fiveMinutesAgo, relativeTo: now, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(result.contains("minute") || result.contains("min"))
    }
}
