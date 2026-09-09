import Foundation
import OSLog

public protocol __MODULE_NAME__LoggerProtocol {
    func debug(_ message: String)
    func info(_ message: String)
    func error(_ message: String)
}

public final class __MODULE_NAME__Logger: __MODULE_NAME__LoggerProtocol {
    private let logger: Logger

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.example", category: String = "App") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
