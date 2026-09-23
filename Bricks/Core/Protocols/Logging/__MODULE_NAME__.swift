import Foundation

/// Severity level of a log message.
public enum LogLevel: String, CaseIterable, Comparable, Sendable {
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
}

/// Abstract logging protocol contract for structured logging across application layers.
public protocol __MODULE_NAME__: Sendable {
    func log(_ level: LogLevel, _ message: String, file: String, line: Int, function: String)
}

public extension __MODULE_NAME__ {
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
