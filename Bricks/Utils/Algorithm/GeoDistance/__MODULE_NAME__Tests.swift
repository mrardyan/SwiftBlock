import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testHaversineDistanceBetweenJakartaAndBandung() {
        let jakarta = GeoPoint(latitude: -6.2088, longitude: 106.8456)
        let bandung = GeoPoint(latitude: -6.9175, longitude: 107.6191)

        let distance = __MODULE_NAME__.distance(from: jakarta, to: bandung)
        // Distance ~118 km (118,000 meters +/- 5,000m)
        XCTAssertGreaterThan(distance, 110_000)
        XCTAssertLessThan(distance, 130_000)
    }

    func testBearingAndCompassHeading() {
        let origin = GeoPoint(latitude: 0.0, longitude: 0.0)
        let northPoint = GeoPoint(latitude: 10.0, longitude: 0.0)
        let eastPoint = GeoPoint(latitude: 0.0, longitude: 10.0)

        let northBearing = __MODULE_NAME__.bearing(from: origin, to: northPoint)
        XCTAssertEqual(northBearing, 0.0, accuracy: 0.1)
        XCTAssertEqual(__MODULE_NAME__.compassHeading(forBearing: northBearing), "N")

        let eastBearing = __MODULE_NAME__.bearing(from: origin, to: eastPoint)
        XCTAssertEqual(eastBearing, 90.0, accuracy: 0.1)
        XCTAssertEqual(__MODULE_NAME__.compassHeading(forBearing: eastBearing), "E")
    }

    func testDestinationPoint() {
        let origin = GeoPoint(latitude: 0.0, longitude: 0.0)
        let destination = __MODULE_NAME__.destinationPoint(from: origin, distanceMeters: 111_195, bearingDegrees: 0) // ~1 degree latitude north

        XCTAssertEqual(destination.latitude, 1.0, accuracy: 0.05)
        XCTAssertEqual(destination.longitude, 0.0, accuracy: 0.05)
    }
}
