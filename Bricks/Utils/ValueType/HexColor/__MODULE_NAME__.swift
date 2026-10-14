import Foundation

/// Errors thrown by hex color parsing.
public enum HexColorError: Error, Equatable, Sendable {
    case invalidHexString(String)
}

/// Type-safe representation of a color from hex string with RGBA component extraction.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = max(0, min(1, red))
        self.green = max(0, min(1, green))
        self.blue = max(0, min(1, blue))
        self.alpha = max(0, min(1, alpha))
    }

    public init(hex: String) throws {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }

        var hexValue: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&hexValue) else {
            throw HexColorError.invalidHexString(hex)
        }

        switch cleaned.count {
        case 6: // RRGGBB
            self.red   = Double((hexValue >> 16) & 0xFF) / 255.0
            self.green = Double((hexValue >> 8) & 0xFF) / 255.0
            self.blue  = Double(hexValue & 0xFF) / 255.0
            self.alpha = 1.0
        case 8: // RRGGBBAA
            self.red   = Double((hexValue >> 24) & 0xFF) / 255.0
            self.green = Double((hexValue >> 16) & 0xFF) / 255.0
            self.blue  = Double((hexValue >> 8) & 0xFF) / 255.0
            self.alpha = Double(hexValue & 0xFF) / 255.0
        default:
            throw HexColorError.invalidHexString(hex)
        }
    }

    public init(stringLiteral value: String) {
        try! self.init(hex: value)
    }

    /// Hex string representation (e.g. "#FF5733").
    public var hexString: String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        if alpha < 1.0 {
            let a = Int(alpha * 255)
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    public var description: String {
        hexString
    }

    /// RGB integer tuple (0-255).
    public var rgb: (r: Int, g: Int, b: Int) {
        (Int(red * 255), Int(green * 255), Int(blue * 255))
    }
}
