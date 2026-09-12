import XCTest
@testable import __MODULE_NAME__

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
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

    func testSystemPermissionTypes() {
        XCTAssertEqual(SystemPermissionType.allCases.count, 5)
        XCTAssertEqual(PermissionStatus.authorized.rawValue, "Authorized")
    }

    func testStatusDoesNotCrash() {
        for permission in SystemPermissionType.allCases {
            let status = manager.status(for: permission)
            XCTAssertFalse(status.rawValue.isEmpty)
        }
    }

    func testBatchRequestDoesNotCrash() async {
        let results = await manager.requestPermissions([.camera, .microphone])
        XCTAssertNotNil(results[.camera])
        XCTAssertNotNil(results[.microphone])
    }
}
