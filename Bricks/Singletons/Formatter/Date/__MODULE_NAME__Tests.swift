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

    func testDateToStringAndBack() {
        let now = Date()
        let format = "yyyy-MM-dd"
        let str = formatter.string(from: now, format: format)
        XCTAssertFalse(str.isEmpty)

        let parsedDate = formatter.date(from: str, format: format)
        XCTAssertNotNil(parsedDate)
    }

    func testPerformanceCaching() {
        let date = Date()
        for _ in 0..<1000 {
            let result = formatter.string(from: date, format: "yyyy-MM-dd HH:mm:ss")
            XCTAssertFalse(result.isEmpty)
        }
    }
}
