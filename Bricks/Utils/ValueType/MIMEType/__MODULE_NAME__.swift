import Foundation

/// Errors thrown by MIMEType validation.
public enum MIMETypeError: Error, Equatable, Sendable {
    case invalidFormat(String)
}

/// Type-safe representation of a MIME (Multipurpose Internet Mail Extensions) media type.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let type: String
    public let subtype: String

    public var rawValue: String {
        "\(type)/\(subtype)"
    }

    public var description: String {
        rawValue
    }

    public init(type: String, subtype: String) throws {
        let cleanType = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanSubtype = subtype.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanType.isEmpty, !cleanSubtype.isEmpty,
              cleanType.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }),
              cleanSubtype.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." || $0 == "+" }) else {
            throw MIMETypeError.invalidFormat("\(type)/\(subtype)")
        }
        self.type = cleanType
        self.subtype = cleanSubtype
    }

    public init(string: String) throws {
        let parts = string.split(separator: "/", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            throw MIMETypeError.invalidFormat(string)
        }
        try self.init(type: parts[0], subtype: parts[1])
    }

    public init(stringLiteral value: String) {
        try! self.init(string: value)
    }

    // Common presets
    public static let json: __MODULE_NAME__ = "application/json"
    public static let xml: __MODULE_NAME__ = "application/xml"
    public static let pdf: __MODULE_NAME__ = "application/pdf"
    public static let png: __MODULE_NAME__ = "image/png"
    public static let jpeg: __MODULE_NAME__ = "image/jpeg"
    public static let gif: __MODULE_NAME__ = "image/gif"
    public static let mp3: __MODULE_NAME__ = "audio/mpeg"
    public static let mp4: __MODULE_NAME__ = "video/mp4"
    public static let html: __MODULE_NAME__ = "text/html"
    public static let plainText: __MODULE_NAME__ = "text/plain"

    // Category checkers
    public var isImage: Bool { type == "image" }
    public var isAudio: Bool { type == "audio" }
    public var isVideo: Bool { type == "video" }
    public var isText: Bool { type == "text" }
    public var isApplication: Bool { type == "application" }
}
