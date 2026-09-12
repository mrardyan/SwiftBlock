import XCTest
@testable import __MODULE_NAME__

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class __MODULE_NAME__Tests: XCTestCase {
    private var manager: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        manager = __MODULE_NAME__()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testBiometricTypeEnum() {
        XCTAssertEqual(BiometricType.faceID.rawValue, "Face ID")
        XCTAssertEqual(BiometricType.touchID.rawValue, "Touch ID")
        XCTAssertEqual(BiometricType.none.rawValue, "None")
    }

    func testCanEvaluateBiometricsDoesNotCrash() {
        let canEvaluate = manager.canEvaluateBiometrics()
        XCTAssertTrue(canEvaluate || !canEvaluate)
    }
}
