import Foundation

/// Options to customize URL validation rules.
public struct URLValidationOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Requires the scheme to be HTTPS.
    public static let requireHTTPS       = URLValidationOptions(rawValue: 1 << 0)
    /// Requires a non-empty host component.
    public static let requireHost        = URLValidationOptions(rawValue: 1 << 1)
    /// Disallows local IP addresses (e.g. 127.0.0.1 or localhost).
    public static let disallowLocalhost  = URLValidationOptions(rawValue: 1 << 2)

    public static let standard: URLValidationOptions = [.requireHost]
    public static let secure: URLValidationOptions = [.requireHTTPS, .requireHost, .disallowLocalhost]
}

/// Defines standard interface for URL validation.
public protocol URLValidatorProtocol: Sendable {
    func validate(_ urlString: String) -> Bool
    func validate(_ url: URL) -> Bool
}

/// Thread-safe URL validator implementing RFC 3986 compliance.
public final class __MODULE_NAME__: URLValidatorProtocol {
    /// Shared singleton instance with standard validation rules.
    public static let shared = __MODULE_NAME__()

    public let options: URLValidationOptions

    /// Initializes a new URL validator with specified validation options.
    /// - Parameter options: Options set controlling URL constraints.
    public init(options: URLValidationOptions = .standard) {
        self.options = options
    }

    /// Validates whether a given string is a valid URL matching configured options.
    public func validate(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let components = URLComponents(string: trimmed) else {
            return false
        }
        return validateComponents(components)
    }

    /// Validates a `URL` instance against configured options.
    public func validate(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        return validateComponents(components)
    }

    private func validateComponents(_ components: URLComponents) -> Bool {
        guard let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return false
        }

        if options.contains(.requireHTTPS) && scheme != "https" {
            return false
        }

        if options.contains(.requireHost) {
            guard let host = components.host, !host.isEmpty else { return false }
        }

        if options.contains(.disallowLocalhost), let host = components.host {
            if host.lowercased() == "localhost" || host == "127.0.0.1" || host == "::1" {
                return false
            }
        }

        return true
    }
}
