import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

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

    func testDurationFormatting() {
        let result = formatter.string(from: 135) // 2 min 15 sec
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.contains("2:15") == true || result?.contains("02:15") == true)
    }
}
