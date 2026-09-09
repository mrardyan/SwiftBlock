import Foundation
import OSLog

public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fault = "FAULT"
}

public protocol __MODULE_NAME__Logger {
    func debug(_ message: String, file: String, line: Int, function: String)
    func info(_ message: String, file: String, line: Int, function: String)
    func warning(_ message: String, file: String, line: Int, function: String)
    func error(_ message: String, file: String, line: Int, function: String)
    func fault(_ message: String, file: String, line: Int, function: String)
}

public extension __MODULE_NAME__Logger {
    func debug(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        debug(message, file: file, line: line, function: function)
    }
    func info(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        info(message, file: file, line: line, function: function)
    }
    func warning(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        warning(message, file: file, line: line, function: function)
    }
    func error(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        error(message, file: file, line: line, function: function)
    }
    func fault(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        fault(message, file: file, line: line, function: function)
    }
}

public final class Default__MODULE_NAME__Logger: __MODULE_NAME__Logger {
    private let logger: Logger

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.example", category: String = "App") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func debug(_ message: String, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.debug("🐛 [\(fileName):\(line) \(function)] \(message, privacy: .public)")
    }

    public func info(_ message: String, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.info("ℹ️ [\(fileName):\(line) \(function)] \(message, privacy: .public)")
    }

    public func warning(_ message: String, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.warning("⚠️ [\(fileName):\(line) \(function)] \(message, privacy: .public)")
    }

    public func error(_ message: String, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.error("❌ [\(fileName):\(line) \(function)] \(message, privacy: .public)")
    }

    public func fault(_ message: String, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.fault("💥 [\(fileName):\(line) \(function)] \(message, privacy: .public)")
    }
}
