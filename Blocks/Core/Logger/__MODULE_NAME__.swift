import Foundation
import OSLog

/// Severity level of a log message.
public enum LogLevel: String, CaseIterable, Comparable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fault = "FAULT"

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.debug, .info, .warning, .error, .fault]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else { return false }
        return lhsIndex < rhsIndex
    }

    /// Associated emoji indicator for console output.
    public var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fault: return "💥"
        }
    }
}

/// A type that logs messages with severity levels and call-site metadata.
public protocol Logging {
    func log(_ level: LogLevel, _ message: String, file: String, line: Int, function: String)
}

public extension Logging {
    func log(_ level: LogLevel, _ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level, message, file: file, line: line, function: function)
    }

    func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.debug, message, file: file, line: line, function: function)
    }

    func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.info, message, file: file, line: line, function: function)
    }

    func warning(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.warning, message, file: file, line: line, function: function)
    }

    func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.error, message, file: file, line: line, function: function)
    }

    func fault(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.fault, message, file: file, line: line, function: function)
    }
}

/// Unified Apple `OSLog` logging implementation.
public final class __MODULE_NAME__: Logging {
    private let logger: Logger

    /// Creates a logger configured for a specific subsystem and category.
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.example", category: String = "App") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ level: LogLevel, _ message: String, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = "\(level.emoji) [\(fileName):\(line) \(function)] \(message)"

        switch level {
        case .debug:
            logger.debug("\(formattedMessage, privacy: .public)")
        case .info:
            logger.info("\(formattedMessage, privacy: .public)")
        case .warning:
            logger.warning("\(formattedMessage, privacy: .public)")
        case .error:
            logger.error("\(formattedMessage, privacy: .public)")
        case .fault:
            logger.fault("\(formattedMessage, privacy: .public)")
        }
    }
}
