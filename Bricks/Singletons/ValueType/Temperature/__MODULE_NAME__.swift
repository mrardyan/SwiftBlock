import Foundation

/// Type-safe representation of temperature in Celsius with unit conversions and localization.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let celsius: Double

    public init(celsius: Double) {
        self.celsius = celsius
    }

    public init(fahrenheit: Double) {
        self.celsius = (fahrenheit - 32.0) * (5.0 / 9.0)
    }

    public init(kelvin: Double) {
        self.celsius = kelvin - 273.15
    }

    public init(floatLiteral value: Double) {
        self.celsius = value
    }

    public init(integerLiteral value: Int) {
        self.celsius = Double(value)
    }

    public var fahrenheit: Double {
        (celsius * 9.0 / 5.0) + 32.0
    }

    public var kelvin: Double {
        celsius + 273.15
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = locale
        let tempStr = formatter.string(from: NSNumber(value: celsius)) ?? "\(celsius)"
        return "\(tempStr) °C"
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.celsius < rhs.celsius
    }
}

// MARK: - BodyTemperature (Health Context)

/// Body temperature condition classification.
public enum FeverState: String, Codable, Equatable, Sendable {
    case hypothermia = "Hypothermia"
    case normal = "Normal"
    case lowFever = "Low Fever"
    case highFever = "High Fever"
}

/// Convenient typealias for health/medical context.
public typealias BodyTemperature = __MODULE_NAME__

extension BodyTemperature {
    /// Fever state classification for human body temperature (valid range: 25°C - 45°C).
    /// Returns nil if temperature is outside plausible body temperature range.
    public var feverState: FeverState? {
        guard (25.0...45.0).contains(celsius) else { return nil }
        switch celsius {
        case ..<35.0: return .hypothermia
        case 35.0..<37.5: return .normal
        case 37.5..<38.5: return .lowFever
        default: return .highFever
        }
    }
}
