import Foundation

/// Errors thrown by license plate validation.
public enum LicensePlateError: Error, Equatable, Sendable {
    case invalidLength(String)
}

/// Type-safe representation of vehicle license plate numbers (e.g. "B 1234 ABC").
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let plateNumber: String

    public init(plateNumber: String) throws {
        let cleaned = plateNumber.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard (3...12).contains(cleaned.count) else {
            throw LicensePlateError.invalidLength(plateNumber)
        }
        self.plateNumber = cleaned
    }

    public init(stringLiteral value: String) {
        let cleaned = value.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.plateNumber = cleaned
    }

    public var description: String {
        plateNumber
    }

    public var formatted: String {
        plateNumber
    }
}
