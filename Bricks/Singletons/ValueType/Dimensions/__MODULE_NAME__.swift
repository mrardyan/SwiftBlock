import Foundation

/// Errors thrown by dimensions validation.
public enum DimensionsError: Error, Equatable, Sendable {
    case invalidDimension(length: Double, width: Double, height: Double)
}

/// Type-safe representation of 3D dimensions in centimeters (length x width x height).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable {
    public let lengthCentimeters: Double
    public let widthCentimeters: Double
    public let heightCentimeters: Double

    public init(length: Double, width: Double, height: Double) throws {
        guard length >= 0, width >= 0, height >= 0 else {
            throw DimensionsError.invalidDimension(length: length, width: width, height: height)
        }
        self.lengthCentimeters = length
        self.widthCentimeters = width
        self.heightCentimeters = height
    }

    /// Volume in cubic centimeters (cm³)
    public var volumeCubicCentimeters: Double {
        lengthCentimeters * widthCentimeters * heightCentimeters
    }

    /// Volume in liters (L)
    public var volumeLiters: Double {
        volumeCubicCentimeters / 1000.0
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.locale = locale

        let l = formatter.string(from: NSNumber(value: lengthCentimeters)) ?? "\(lengthCentimeters)"
        let w = formatter.string(from: NSNumber(value: widthCentimeters)) ?? "\(widthCentimeters)"
        let h = formatter.string(from: NSNumber(value: heightCentimeters)) ?? "\(heightCentimeters)"

        return "\(l) x \(w) x \(h) cm"
    }
}
