import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testRatingClampingAndFormatting() throws {
        let r1: __MODULE_NAME__ = 4.8
        XCTAssertEqual(r1.score, 4.8)
        XCTAssertEqual(r1.roundedHalfStar, 5.0)
        XCTAssertEqual(r1.formatted(locale: Locale(identifier: "en_US")), "4.8 / 5.0")
        XCTAssertEqual(r1.starIconsString, "★★★★½")

        let r2: __MODULE_NAME__ = 3.0
        XCTAssertEqual(r2.starIconsString, "★★★☆☆")
    }

    func testInvalidRatingThrowsWithoutClamping() {
        XCTAssertThrowsError(try __MODULE_NAME__(score: 6.5, clamped: false)) { error in
            XCTAssertEqual(error as? RatingError, RatingError.invalidScore(6.5))
        }
    }
}
