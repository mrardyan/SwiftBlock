import Foundation

/// Defines standard interface for number formatting.
public protocol NumberFormatterProtocol: Sendable {
    func string(from number: NSNumber, style: NumberFormatter.Style, locale: Locale) -> String?
}

/// Thread-safe number formatter singleton wrapping `NumberFormatter`.
public final class __MODULE_NAME__: @unchecked Sendable, NumberFormatterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let formatter: NumberFormatter

    public init() {
        self.formatter = NumberFormatter()
    }

    /// Formats an `NSNumber` into a string using specified style and locale.
    public func string(from number: NSNumber, style: NumberFormatter.Style = .decimal, locale: Locale = .current) -> String? {
        lock.lock()
        defer { lock.unlock() }
        formatter.numberStyle = style
        formatter.locale = locale
        return formatter.string(from: number)
    }
}
