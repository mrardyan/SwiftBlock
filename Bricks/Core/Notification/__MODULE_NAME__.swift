import Foundation
import UserNotifications

/// Defines standard interface for local and push notification scheduling operations.
@available(macOS 10.14, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
public protocol AppNotificationSchedulerProtocol: Sendable {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func scheduleLocalNotification(id: String, title: String, body: String, timeInterval: TimeInterval, repeats: Bool) async throws
    func cancelNotification(withId id: String)
    func cancelAllNotifications()
}

/// Thread-safe notification scheduler singleton wrapping `UNUserNotificationCenter`.
@available(macOS 10.14, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
public final class __MODULE_NAME__: @unchecked Sendable, AppNotificationSchedulerProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let customCenter: UNUserNotificationCenter?

    public init(center: UNUserNotificationCenter? = nil) {
        self.customCenter = center
    }

    private var center: UNUserNotificationCenter? {
        if let customCenter = customCenter {
            return customCenter
        }
        if Bundle.main.bundleIdentifier != nil {
            return UNUserNotificationCenter.current()
        }
        return nil
    }

    /// Requests notification permissions (alert, badge, sound) from the user.
    public func requestAuthorization(options: UNAuthorizationOptions = [.alert, .badge, .sound]) async throws -> Bool {
        guard let center = center else { return false }
        return try await center.requestAuthorization(options: options)
    }

    /// Schedules a local notification after a specified time interval.
    public func scheduleLocalNotification(
        id: String,
        title: String,
        body: String,
        timeInterval: TimeInterval,
        repeats: Bool = false
    ) async throws {
        guard let center = center else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await center.add(request)
    }

    /// Cancels a pending notification with the specified identifier.
    public func cancelNotification(withId id: String) {
        center?.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancels all pending local notifications.
    public func cancelAllNotifications() {
        center?.removeAllPendingNotificationRequests()
    }
}
