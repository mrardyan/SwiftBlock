import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testCircularGeofence() {
        let center = GeofencePoint(latitude: -6.2088, longitude: 106.8456)
        let insidePoint = GeofencePoint(latitude: -6.2090, longitude: 106.8458) // ~30m away
        let outsidePoint = GeofencePoint(latitude: -6.2500, longitude: 106.8456) // ~4.5km away

        XCTAssertTrue(__MODULE_NAME__.isPointInCircle(insidePoint, center: center, radiusMeters: 100))
        XCTAssertFalse(__MODULE_NAME__.isPointInCircle(outsidePoint, center: center, radiusMeters: 100))
    }

    func testPolygonRayCastingGeofence() {
        // Rectangle vertices around Monas area
        let polygon = [
            GeofencePoint(latitude: -6.1700, longitude: 106.8200),
            GeofencePoint(latitude: -6.1700, longitude: 106.8350),
            GeofencePoint(latitude: -6.1800, longitude: 106.8350),
            GeofencePoint(latitude: -6.1800, longitude: 106.8200)
        ]

        let inside = GeofencePoint(latitude: -6.1754, longitude: 106.8272)
        let outside = GeofencePoint(latitude: -6.1600, longitude: 106.8272)

        XCTAssertTrue(__MODULE_NAME__.isPointInPolygon(inside, vertices: polygon))
        XCTAssertFalse(__MODULE_NAME__.isPointInPolygon(outside, vertices: polygon))
    }
}
