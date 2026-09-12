import XCTest
import UserNotifications
@testable import __MODULE_NAME__

@available(macOS 10.14, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
final class __MODULE_NAME__Tests: XCTestCase {
    private var scheduler: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        scheduler = __MODULE_NAME__()
    }

    override func tearDown() {
        scheduler = nil
        super.tearDown()
    }

    func testSchedulerInitialization() {
        XCTAssertNotNil(scheduler)
    }
}
