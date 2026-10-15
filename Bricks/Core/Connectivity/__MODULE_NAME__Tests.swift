import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
{{#if concurrency == 'swift-concurrency'}}
    func testMockConnectivity() async {
        let mockStatus = ConnectivityStatus(isConnected: true, interfaceType: .wifi, isExpensive: false)
        let connectivity = __MODULE_NAME__(mockStatus: mockStatus)

        let isConnected = await connectivity.isConnected
        let status = await connectivity.status
        XCTAssertTrue(isConnected)
        XCTAssertEqual(status.interfaceType, .wifi)

        await connectivity.updateMockStatus(ConnectivityStatus(isConnected: false, interfaceType: .none))
        let isConnectedAfter = await connectivity.isConnected
        let statusAfter = await connectivity.status
        XCTAssertFalse(isConnectedAfter)
        XCTAssertEqual(statusAfter.interfaceType, .none)
    }

    func testStatusUpdatesStream() async {
        let mockStatus = ConnectivityStatus(isConnected: true, interfaceType: .wifi)
        let connectivity = __MODULE_NAME__(mockStatus: mockStatus)

        let stream = await connectivity.statusUpdates
        var iterator = stream.makeAsyncIterator()

        let initial = await iterator.next()
        XCTAssertEqual(initial?.isConnected, true)

        await connectivity.updateMockStatus(ConnectivityStatus(isConnected: false, interfaceType: .none))
        let updated = await iterator.next()
        XCTAssertEqual(updated?.isConnected, false)
    }
{{else}}
    func testMockConnectivity() {
        let mockStatus = ConnectivityStatus(isConnected: true, interfaceType: .wifi, isExpensive: false)
        let connectivity = __MODULE_NAME__(mockStatus: mockStatus)

        XCTAssertTrue(connectivity.isConnected)
        XCTAssertEqual(connectivity.status.interfaceType, .wifi)

        connectivity.updateMockStatus(ConnectivityStatus(isConnected: false, interfaceType: .none))
        XCTAssertFalse(connectivity.isConnected)
        XCTAssertEqual(connectivity.status.interfaceType, .none)
    }
{{/if}}
}
