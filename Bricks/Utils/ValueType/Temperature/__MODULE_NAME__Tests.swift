import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testTemperatureConversionsAndFormatting() {
        let temp: __MODULE_NAME__ = 25.0
        XCTAssertEqual(temp.celsius, 25.0)
        XCTAssertEqual(temp.fahrenheit, 77.0)
        XCTAssertEqual(temp.kelvin, 298.15)
        XCTAssertEqual(temp.formatted(locale: Locale(identifier: "en_US")), "25.0 °C")
    }

    func testNegativeTemperature() {
        let freezing: __MODULE_NAME__ = -10
        XCTAssertEqual(freezing.celsius, -10.0)
        XCTAssertEqual(freezing.formatted(locale: Locale(identifier: "en_US")), "-10.0 °C")
    }

    func testBodyTemperatureFeverState() {
        let normal: BodyTemperature = 36.6
        XCTAssertEqual(normal.feverState, FeverState.normal)

        let fever: BodyTemperature = 39.0
        XCTAssertEqual(fever.feverState, FeverState.highFever)

        let outOfRange: BodyTemperature = -5.0
        XCTAssertNil(outOfRange.feverState)
    }
}
