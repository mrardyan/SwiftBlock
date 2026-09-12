import XCTest
@testable import __MODULE_NAME__

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

    func testByteCountFormatting() {
        let kilobytes = formatter.string(fromByteCount: 1024)
        XCTAssertTrue(kilobytes.contains("KB") || kilobytes.contains("kB"))

        let megabytes = formatter.string(fromByteCount: 5 * 1024 * 1024)
        XCTAssertTrue(megabytes.contains("MB"))
    }
}
