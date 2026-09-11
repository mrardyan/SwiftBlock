import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __PROJECT_NAME__

private final class MockAnalyticsProvider: AnalyticsProvider {
    var identifier: AnalyticsProviderIdentifier = .console
    var trackedEvents: [AnalyticsEvent] = []
    var userId: String?
    var userProperties: [String: String] = [:]

    func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }

    func setUserId(_ userId: String?) {
        self.userId = userId
    }

    func setUserProperty(key: String, value: String?) {
        if let val = value {
            userProperties[key] = val
        } else {
            userProperties.removeValue(forKey: key)
        }
    }
}

private struct TestEvent: AnalyticsEvent {
    var name: String = "test_event"
    var parameters: [String: Any]? = ["key": "value"]
    var targetProviders: [AnalyticsProviderIdentifier]? = nil
}

final class __MODULE_NAME__Tests: XCTestCase {
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
}
