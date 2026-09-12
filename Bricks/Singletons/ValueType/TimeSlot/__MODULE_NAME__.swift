import Foundation

/// Errors thrown by time slot validation.
public enum TimeSlotError: Error, Equatable, Sendable {
    case endBeforeStart(start: Date, end: Date)
}

/// Type-safe representation of a time slot defined by a start and end date.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) throws {
        guard end > start else {
            throw TimeSlotError.endBeforeStart(start: start, end: end)
        }
        self.start = start
        self.end = end
    }

    /// Duration of the time slot in seconds.
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    /// Duration in minutes.
    public var durationMinutes: Double {
        duration / 60.0
    }

    /// Whether a given date falls within this time slot.
    public func contains(_ date: Date) -> Bool {
        (start...end).contains(date)
    }

    /// Whether this time slot overlaps with another.
    public func overlaps(with other: __MODULE_NAME__) -> Bool {
        start < other.end && other.start < end
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = locale
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
