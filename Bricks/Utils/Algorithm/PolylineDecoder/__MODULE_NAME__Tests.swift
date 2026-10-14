import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDecodeGooglePolyline() {
        // Known sample polyline: Points (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
        let polyline = "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
        let points = __MODULE_NAME__.decode(polyline)

        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points[0].latitude, 38.5, accuracy: 0.0001)
        XCTAssertEqual(points[0].longitude, -120.2, accuracy: 0.0001)
        XCTAssertEqual(points[1].latitude, 40.7, accuracy: 0.0001)
        XCTAssertEqual(points[1].longitude, -120.95, accuracy: 0.0001)
    }

    func testEncodeAndDecodeRoundtrip() {
        let original = [
            PolylineCoordinate(latitude: -6.2088, longitude: 106.8456),
            PolylineCoordinate(latitude: -6.2100, longitude: 106.8480),
            PolylineCoordinate(latitude: -6.2150, longitude: 106.8500)
        ]

        let encoded = __MODULE_NAME__.encode(original)
        XCTAssertFalse(encoded.isEmpty)

        let decoded = __MODULE_NAME__.decode(encoded)
        XCTAssertEqual(decoded.count, original.count)
        for i in 0..<original.count {
            XCTAssertEqual(decoded[i].latitude, original[i].latitude, accuracy: 0.00001)
            XCTAssertEqual(decoded[i].longitude, original[i].longitude, accuracy: 0.00001)
        }
    }
}
