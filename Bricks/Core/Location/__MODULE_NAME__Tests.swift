import XCTest
import CoreLocation
@testable import __MODULE_NAME__

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class __MODULE_NAME__Tests: XCTestCase {
    private var service: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        service = __MODULE_NAME__()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testAuthorizationStatusCheck() {
        let status = service.authorizationStatus
        #if os(iOS) || os(watchOS) || os(tvOS)
        XCTAssertTrue(status == .notDetermined || status == .authorizedWhenInUse || status == .authorizedAlways || status == .denied || status == .restricted)
        #else
        XCTAssertTrue(status == .notDetermined || status == .authorizedAlways || status == .denied || status == .restricted)
        #endif
    }
}
