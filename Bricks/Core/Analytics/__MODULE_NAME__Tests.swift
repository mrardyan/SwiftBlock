import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

private final class MockAnalyticsProvider: AnalyticsProvider, @unchecked Sendable {
    private let lock = NSLock()
    var identifier: AnalyticsProviderIdentifier = .console
    var trackedEvents: [any AnalyticsEvent] = []
    var userId: String?
    var userProperties: [String: String] = [:]

    func track(_ event: any AnalyticsEvent) {
        lock.lock()
        defer { lock.unlock() }
        trackedEvents.append(event)
    }

    func setUserId(_ userId: String?) {
        lock.lock()
        defer { lock.unlock() }
        self.userId = userId
    }

    func setUserProperty(key: String, value: String?) {
        lock.lock()
        defer { lock.unlock() }
        if let val = value {
            userProperties[key] = val
        } else {
            userProperties.removeValue(forKey: key)
        }
    }
}

private struct TestEvent: AnalyticsEvent {
    var name: String = "test_event"
    var parameters: [String: any Sendable]? = ["key": "value"]
    var targetProviders: [AnalyticsProviderIdentifier]? = nil
}

final class __MODULE_NAME__Tests: XCTestCase {
{{#if concurrency == 'swift-concurrency'}}
    func testEventTrackingAndUserProperties() async {
        let mockProvider = MockAnalyticsProvider()
        let analytics = __MODULE_NAME__(providers: [mockProvider])

        let event = TestEvent()
        await analytics.track(event)
        XCTAssertEqual(mockProvider.trackedEvents.count, 1)
        XCTAssertEqual(mockProvider.trackedEvents.first?.name, "test_event")

        await analytics.setUserId("user_789")
        XCTAssertEqual(mockProvider.userId, "user_789")

        await analytics.setUserProperty(key: "plan", value: "pro")
        XCTAssertEqual(mockProvider.userProperties["plan"], "pro")
    }
{{else}}
    func testEventTrackingAndUserProperties() {
        let mockProvider = MockAnalyticsProvider()
        let analytics = __MODULE_NAME__(providers: [mockProvider])

        let event = TestEvent()
        analytics.track(event)
        XCTAssertEqual(mockProvider.trackedEvents.count, 1)
        XCTAssertEqual(mockProvider.trackedEvents.first?.name, "test_event")

        analytics.setUserId("user_789")
        XCTAssertEqual(mockProvider.userId, "user_789")

        analytics.setUserProperty(key: "plan", value: "pro")
        XCTAssertEqual(mockProvider.userProperties["plan"], "pro")
    }
{{/if}}
}
