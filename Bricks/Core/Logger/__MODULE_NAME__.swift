import Foundation
import OSLog

/// Unified Apple `OSLog` logging implementation.
public final class __MODULE_NAME__: Logging, @unchecked Sendable {

    private let logger: Logger

    /// Creates a logger configured for a specific subsystem and category.
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.example", category: String = "App") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ level: LogLevel, _ message: String, file: String, line: Int, function: String) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let resetCode = "\u{001B}[0m"
        let formattedMessage = "\(level.colorCode)[\(level.rawValue)] [\(fileName):\(line) \(function)] \(message)\(resetCode)"

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
