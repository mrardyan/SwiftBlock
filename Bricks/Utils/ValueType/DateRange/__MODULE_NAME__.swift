import Foundation

/// Errors thrown by date range validation.
public enum DateRangeError: Error, Equatable, Sendable {
    case endBeforeStart(start: Date, end: Date)
}

/// Type-safe representation of a date range (start to end).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable {
    public let startDate: Date
    public let endDate: Date

    public init(start: Date, end: Date) throws {
        guard end >= start else {
            throw DateRangeError.endBeforeStart(start: start, end: end)
        }
        self.startDate = start
        self.endDate = end
    }

    /// Number of calendar days in the range (inclusive).
    public var numberOfDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }

    /// Total duration in seconds.
    public var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    /// Whether a given date falls within this range.
    public func contains(_ date: Date) -> Bool {
        (startDate...endDate).contains(date)
    }

    /// Whether this range overlaps with another range.
    public func overlaps(with other: __MODULE_NAME__) -> Bool {
        startDate <= other.endDate && other.startDate <= endDate
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = locale
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}
