import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testGeohashEncodingAndDecoding() {
        // Monas Jakarta (-6.1754, 106.8272)
        let hash = __MODULE_NAME__.encode(latitude: -6.1754, longitude: 106.8272, precision: 6)
        XCTAssertFalse(hash.isEmpty)
        XCTAssertEqual(hash.count, 6)

        let decoded = __MODULE_NAME__.decode(geohash: hash)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded!.centerLat, -6.1754, accuracy: 0.05)
        XCTAssertEqual(decoded!.centerLon, 106.8272, accuracy: 0.05)
    }

    func testGeohashNeighbors() {
        let hash = "qqgvk1"
        let neighbors = __MODULE_NAME__.neighbors(for: hash)

        XCTAssertNotNil(neighbors)
        XCTAssertEqual(neighbors!.all.count, 8)
        XCTAssertTrue(neighbors!.all.allSatisfy { $0.count == 6 })
    }
}
