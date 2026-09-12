import Foundation

/// Errors thrown by duration validation.
public enum DurationError: Error, Equatable, Sendable {
    case negativeDuration(TimeInterval)
}

/// Type-safe representation of time duration in seconds.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let seconds: TimeInterval

    public init(seconds: TimeInterval) throws {
        guard seconds >= 0 else {
            throw DurationError.negativeDuration(seconds)
        }
        self.seconds = seconds
    }

    public init(floatLiteral value: Double) {
        self.seconds = max(0.0, value)
    }

    public init(integerLiteral value: Int) {
        self.seconds = max(0.0, TimeInterval(value))
    }

    public var minutes: Double {
        seconds / 60.0
    }

    public var hours: Double {
        seconds / 3600.0
    }

    public var formattedHHMMSS: String {
        let totalSecs = Int(seconds)
        let hrs = totalSecs / 3600
        let mins = (totalSecs % 3600) / 60
        let secs = totalSecs % 60

        if hrs > 0 {
            return String(format: "%02d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = DateComponentsFormatter()
        var calendar = Calendar.current
        calendar.locale = locale
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter.string(from: seconds) ?? formattedHHMMSS
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(floatLiteral: lhs.seconds + rhs.seconds)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.seconds < rhs.seconds
    }
}
