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
        if version == .v4 {
            let parts = rawValue.split(separator: ".").compactMap { Int($0) }
            guard parts.count == 4 else { return false }
            // 10.0.0.0/8
            if parts[0] == 10 { return true }
            // 172.16.0.0/12
            if parts[0] == 172 && (16...31).contains(parts[1]) { return true }
            // 192.168.0.0/16
            if parts[0] == 192 && parts[1] == 168 { return true }
            return false
        } else {
            let lower = rawValue.lowercased()
            // IPv6 Unique Local Address: fc00::/7
            if lower.hasPrefix("fc") || lower.hasPrefix("fd") { return true }
            // IPv6 Link-Local: fe80::/10
            if lower.hasPrefix("fe8") || lower.hasPrefix("fe9") || lower.hasPrefix("fea") || lower.hasPrefix("feb") { return true }
            return false
        }
    }

    private static func isValidIPv4(_ string: String) -> Bool {
        var sin = in_addr()
        return string.withCString { inet_pton(AF_INET, $0, &sin) } == 1
    }

    private static func isValidIPv6(_ string: String) -> Bool {
        var sin6 = in6_addr()
        return string.withCString { inet_pton(AF_INET6, $0, &sin6) } == 1
    }
}
