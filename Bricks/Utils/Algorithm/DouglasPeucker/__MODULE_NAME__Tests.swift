import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testStraightLineSimplification() {
        // Collinear points along longitude line
        let points = [
            TrackPoint(latitude: 0.0, longitude: 0.0),
            TrackPoint(latitude: 0.0, longitude: 0.001),
            TrackPoint(latitude: 0.0, longitude: 0.002),
            TrackPoint(latitude: 0.0, longitude: 0.003),
            TrackPoint(latitude: 0.0, longitude: 0.004)
        ]

        let simplified = __MODULE_NAME__.simplify(points, tolerance: 10.0)
        XCTAssertEqual(simplified.count, 2)
        XCTAssertEqual(simplified.first, points.first)
        XCTAssertEqual(simplified.last, points.last)
    }

    func testSharpTurnPreservation() {
        // Path with a prominent turn
        let points = [
            TrackPoint(latitude: 0.0, longitude: 0.0),
            TrackPoint(latitude: 0.0, longitude: 0.01),
            TrackPoint(latitude: 0.05, longitude: 0.01), // Sharp peak (~5.5km deviation)
            TrackPoint(latitude: 0.05, longitude: 0.02)
        ]

        let simplified = __MODULE_NAME__.simplify(points, tolerance: 50.0)
        XCTAssertEqual(simplified.count, 4) // Peak point must be preserved
    }
}
