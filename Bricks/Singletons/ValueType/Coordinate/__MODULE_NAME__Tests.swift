import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testValidCoordinateInitialization() throws {
        let coord = try __MODULE_NAME__(latitude: -6.2088, longitude: 106.8456)
        XCTAssertEqual(coord.latitude, -6.2088)
        XCTAssertEqual(coord.longitude, 106.8456)
    }

    func testInvalidLatitudeThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(latitude: 95.0, longitude: 100.0)) { error in
            XCTAssertEqual(error as? CoordinateError, CoordinateError.invalidLatitude(95.0))
        }
    }

    func testDistanceCalculation() throws {
        // Monas Jakarta (-6.1754, 106.8272) to Senayan (-6.2253, 106.8016) ~6km
        let monas = try __MODULE_NAME__(latitude: -6.1754, longitude: 106.8272)
        let senayan = try __MODULE_NAME__(latitude: -6.2253, longitude: 106.8016)

        let distanceMeters = monas.distance(to: senayan)
        XCTAssertGreaterThan(distanceMeters, 5000)
        XCTAssertLessThan(distanceMeters, 7000)
    }
}
