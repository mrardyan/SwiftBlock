import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __PROJECT_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testLogLevelOrdering() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        XCTAssertTrue(LogLevel.error < LogLevel.fault)
    }

    func testLoggerExecutesWithoutCrashing() {
        let logger = __MODULE_NAME__(subsystem: "com.test", category: "Test")
        logger.debug("Debug log message")
        logger.info("Info log message")
        logger.warning("Warning log message")
        logger.error("Error log message")
        logger.fault("Fault log message")
    }
}
