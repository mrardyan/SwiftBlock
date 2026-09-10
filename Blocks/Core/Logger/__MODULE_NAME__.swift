import Foundation
import OSLog

/// Log levels supported by the unified logging system.
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

    /// Emoji icon representation for console output formatting.
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

/// Interface for logging messages across the application.
public protocol Logging {
    /// Logs a message at the specified log level with source location information.
    func log(_ level: LogLevel, _ message: String, file: String, line: Int, function: String)
}

public extension Logging {
    /// Logs a message at the specified log level.
    func log(_ level: LogLevel, _ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(level, message, file: file, line: line, function: function)
    }

    /// Logs a debug-level message.
    func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.debug, message, file: file, line: line, function: function)
    }

    /// Logs an info-level message.
    func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.info, message, file: file, line: line, function: function)
    }

    /// Logs a warning-level message.
    func warning(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.warning, message, file: file, line: line, function: function)
    }

    /// Logs an error-level message.
    func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.error, message, file: file, line: line, function: function)
    }

    /// Logs a fault-level message.
    func fault(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        log(.fault, message, file: file, line: line, function: function)
    }
}

/// Unified Apple OSLog wrapper implementation for system logging.
public final class __MODULE_NAME__: Logging {
    private let logger: Logger

    /// Initializes a new logger instance with specified subsystem and category.
    /// - Parameters:
    ///   - subsystem: Unique subsystem identifier (defaults to main bundle identifier).
    ///   - category: Category name for filtering logs (defaults to "App").
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.example", category: String = "App") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    /// Logs a message using Apple's OSLog subsystem.
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

