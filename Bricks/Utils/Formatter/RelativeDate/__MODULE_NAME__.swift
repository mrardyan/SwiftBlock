import Foundation

/// Defines standard interface for relative date formatting.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol RelativeDateFormatterProtocol: Sendable {
    func localizedString(for date: Date, relativeTo referenceDate: Date, locale: Locale) -> String
    func localizedString(from timeInterval: TimeInterval, locale: Locale) -> String
}

/// Thread-safe relative date formatter singleton wrapping `RelativeDateTimeFormatter`.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class __MODULE_NAME__: @unchecked Sendable, RelativeDateFormatterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let formatter: RelativeDateTimeFormatter

    public init(unitsStyle: RelativeDateTimeFormatter.UnitsStyle = .full) {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = unitsStyle
        self.formatter = fmt
    }

    /// Formats the time interval between a date and a reference date in relative terms (e.g. "2 hours ago").
    public func localizedString(for date: Date, relativeTo referenceDate: Date = Date(), locale: Locale = .current) -> String {
        lock.lock()
        defer { lock.unlock() }
        formatter.locale = locale
        return formatter.localizedString(for: date, relativeTo: referenceDate)
    }

    /// Formats a time interval in relative terms (e.g. "in 5 minutes").
    public func localizedString(from timeInterval: TimeInterval, locale: Locale = .current) -> String {
        lock.lock()
        defer { lock.unlock() }
        formatter.locale = locale
        return formatter.localizedString(fromTimeInterval: timeInterval)
    }
}
