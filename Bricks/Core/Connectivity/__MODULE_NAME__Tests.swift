import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMockConnectivity() {
        let mockStatus = ConnectivityStatus(isConnected: true, interfaceType: .wifi, isExpensive: false)
        let connectivity = __MODULE_NAME__(mockStatus: mockStatus)

        XCTAssertTrue(connectivity.isConnected)
        XCTAssertEqual(connectivity.status.interfaceType, .wifi)

        connectivity.updateMockStatus(ConnectivityStatus(isConnected: false, interfaceType: .none))
        XCTAssertFalse(connectivity.isConnected)
        XCTAssertEqual(connectivity.status.interfaceType, .none)
    }
}
