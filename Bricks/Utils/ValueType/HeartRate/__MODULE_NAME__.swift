import Foundation

/// Errors thrown by heart rate validation.
public enum HeartRateError: Error, Equatable, Sendable {
    case invalidBPM(Int)
}

/// Cardiac intensity zone classification.
public enum CardiacZone: String, Codable, Equatable, Sendable {
    case resting = "Resting"
    case warmUp = "Warm Up"
    case fatBurn = "Fat Burn"
    case cardio = "Cardio"
    case peak = "Peak"
}

/// Type-safe representation of heart rate in beats per minute (BPM).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByIntegerLiteral {
    public let bpm: Int

    public init(bpm: Int) throws {
        guard (30...240).contains(bpm) else {
            throw HeartRateError.invalidBPM(bpm)
        }
        self.bpm = bpm
    }

    public init(integerLiteral value: Int) {
        self.bpm = max(30, min(240, value))
    }

    /// Calculates cardiac zone based on estimated max heart rate (default 220 - age).
    public func zone(age: Int = 30) -> CardiacZone {
        let maxHR = Double(max(100, 220 - age))
        let percentage = Double(bpm) / maxHR

        switch percentage {
        case ..<0.50: return .resting
        case 0.50..<0.60: return .warmUp
        case 0.60..<0.70: return .fatBurn
        case 0.70..<0.85: return .cardio
        default: return .peak
        }
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        let bpmStr = formatter.string(from: NSNumber(value: bpm)) ?? "\(bpm)"
        return "\(bpmStr) BPM"
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.bpm < rhs.bpm
    }
}
