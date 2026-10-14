import Foundation

/// Errors thrown by rating validation.
public enum RatingError: Error, Equatable, Sendable {
    case invalidScore(Double)
}

/// Type-safe representation of rating scores (0.0 to 5.0 stars).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let score: Double

    public init(score: Double, clamped: Bool = true) throws {
        if clamped {
            self.score = max(0.0, min(5.0, score))
        } else {
            guard (0.0...5.0).contains(score) else {
                throw RatingError.invalidScore(score)
            }
            self.score = score
        }
    }

    public init(floatLiteral value: Double) {
        self.score = max(0.0, min(5.0, value))
    }

    public init(integerLiteral value: Int) {
        self.score = max(0.0, min(5.0, Double(value)))
    }

    /// Rounded score to nearest half star (e.g., 4.3 -> 4.5).
    public var roundedHalfStar: Double {
        (score * 2.0).rounded() / 2.0
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
        let scoreStr = formatter.string(from: NSNumber(value: score)) ?? "\(score)"
        return "\(scoreStr) / 5.0"
    }

    public var starIconsString: String {
        let fullStars = Int(score)
        let hasHalf = (score - Double(fullStars)) >= 0.5
        let emptyStars = 5 - fullStars - (hasHalf ? 1 : 0)

        return String(repeating: "★", count: fullStars) +
               (hasHalf ? "½" : "") +
               String(repeating: "☆", count: emptyStars)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.score < rhs.score
    }
}
