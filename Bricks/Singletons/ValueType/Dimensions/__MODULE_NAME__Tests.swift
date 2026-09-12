import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDimensionsVolumeAndFormatting() throws {
        let dim = try __MODULE_NAME__(length: 10, width: 20, height: 30)
        XCTAssertEqual(dim.volumeCubicCentimeters, 6000.0)
        XCTAssertEqual(dim.volumeLiters, 6.0)
        XCTAssertEqual(dim.formatted(locale: Locale(identifier: "en_US")), "10 x 20 x 30 cm")
    }

    func testNegativeDimensionThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(length: -10, width: 5, height: 5)) { error in
            XCTAssertEqual(error as? DimensionsError, DimensionsError.invalidDimension(length: -10, width: 5, height: 5))
        }
    }
}
