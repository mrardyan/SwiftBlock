import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDurationConversionsAndFormatting() throws {
        let dur = try __MODULE_NAME__(seconds: 3665)
        XCTAssertEqual(dur.hours, 3665 / 3600.0, accuracy: 0.001)
        XCTAssertEqual(dur.formattedHHMMSS, "01:01:05")

        let shortDur = try __MODULE_NAME__(seconds: 125)
        XCTAssertEqual(shortDur.formattedHHMMSS, "02:05")
    }

    func testNegativeDurationThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(seconds: -10)) { error in
            XCTAssertEqual(error as? DurationError, DurationError.negativeDuration(-10))
        }
    }

    func testLiteralsAndAddition() {
        let d1: __MODULE_NAME__ = 60
        let d2: __MODULE_NAME__ = 120.0

        let sum = d1 + d2
        XCTAssertEqual(sum.seconds, 180.0)
        XCTAssertEqual(sum.minutes, 3.0)
    }
}
