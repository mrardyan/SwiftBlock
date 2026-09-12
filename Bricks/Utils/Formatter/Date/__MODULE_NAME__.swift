import Foundation

/// Defines standard interface for date formatting operations.
public protocol DateFormatterProtocol: Sendable {
    func string(from date: Date, format: String, timeZone: TimeZone, locale: Locale) -> String
    func date(from string: String, format: String, timeZone: TimeZone, locale: Locale) -> Date?
}

/// Thread-safe DateFormatter wrapper that caches `DateFormatter` instances to avoid costly initializations.
public final class __MODULE_NAME__: @unchecked Sendable, DateFormatterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private var cache: [String: DateFormatter] = [:]

    public init() {}

    /// Formats a `Date` into a string using the specified format string.
    public func string(from date: Date, format: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone = .current, locale: Locale = .current) -> String {
        let fmt = cachedFormatter(format: format, timeZone: timeZone, locale: locale)
        return fmt.string(from: date)
    }

    /// Parses a date string into a `Date` object using the specified format string.
    public func date(from string: String, format: String = "yyyy-MM-dd HH:mm:ss", timeZone: TimeZone = .current, locale: Locale = .current) -> Date? {
        let fmt = cachedFormatter(format: format, timeZone: timeZone, locale: locale)
        return fmt.date(from: string)
    }

    private func cachedFormatter(format: String, timeZone: TimeZone, locale: Locale) -> DateFormatter {
        let key = "\(format)_\(timeZone.identifier)_\(locale.identifier)"
        lock.lock()
        defer { lock.unlock() }

        if let existing = cache[key] {
            return existing
        }

        let newFmt = DateFormatter()
        newFmt.dateFormat = format
        newFmt.timeZone = timeZone
        newFmt.locale = locale
        cache[key] = newFmt
        return newFmt
    }
}
