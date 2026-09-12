import Foundation

/// Defines standard interface for duration formatting.
public protocol DurationFormatterProtocol: Sendable {
    func string(from timeInterval: TimeInterval) -> String?
}

/// Thread-safe duration formatter singleton wrapping `DateComponentsFormatter`.
public final class __MODULE_NAME__: @unchecked Sendable, DurationFormatterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let formatter: DateComponentsFormatter

    public init(unitsStyle: DateComponentsFormatter.UnitsStyle = .positional, allowedUnits: NSCalendar.Unit = [.minute, .second]) {
        let fmt = DateComponentsFormatter()
        fmt.unitsStyle = unitsStyle
        fmt.allowedUnits = allowedUnits
        fmt.zeroFormattingBehavior = .pad
        self.formatter = fmt
    }

    /// Formats a time interval in seconds into duration string (e.g. "02:15" or "1h 45m").
    public func string(from timeInterval: TimeInterval) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return formatter.string(from: timeInterval)
    }
}
