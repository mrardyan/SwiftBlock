import Foundation

/// Version of IP address.
public enum IPVersion: Sendable, Equatable, Hashable, Codable {
    case v4
    case v6
}

/// Errors thrown by IP address parsing.
public enum IPAddressError: Error, Equatable, Sendable {
    case invalidFormat(String)
}

/// Type-safe representation of an IP address (IPv4 or IPv6).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String
    public let version: IPVersion

    public var description: String {
        rawValue
    }

    public init(rawValue: String) throws {
        let clean = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if __MODULE_NAME__.isValidIPv4(clean) {
            self.rawValue = clean
            self.version = .v4
        } else if __MODULE_NAME__.isValidIPv6(clean) {
            self.rawValue = clean
            self.version = .v6
        } else {
            throw IPAddressError.invalidFormat(rawValue)
        }
    }

    public init(stringLiteral value: String) {
        try! self.init(rawValue: value)
    }

    public var isLoopback: Bool {
        switch version {
        case .v4:
            return rawValue == "127.0.0.1" || rawValue.hasPrefix("127.")
        case .v6:
            return rawValue == "::1" || rawValue == "0:0:0:0:0:0:0:1"
        }
    }

    public var isPrivate: Bool {
        guard version == .v4 else { return false }
        let parts = rawValue.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else { return false }
        // 10.0.0.0/8
        if parts[0] == 10 { return true }
        // 172.16.0.0/12
        if parts[0] == 172 && (16...31).contains(parts[1]) { return true }
        // 192.168.0.0/16
        if parts[0] == 192 && parts[1] == 168 { return true }
        return false
    }

    private static func isValidIPv4(_ string: String) -> Bool {
        let parts = string.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        for part in parts {
            guard let num = Int(part), (0...255).contains(num) else { return false }
            if part.count > 1 && part.hasPrefix("0") { return false } // No leading zeros
        }
        return true
    }

    private static func isValidIPv6(_ string: String) -> Bool {
        let parts = string.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count >= 3 && parts.count <= 8 else { return false }
        for part in parts {
            if part.isEmpty { continue } // zero compression ::
            guard part.count <= 4, Int(part, radix: 16) != nil else { return false }
        }
        return true
    }
}
