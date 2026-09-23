import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    final class InMemoryLogger: __MODULE_NAME__, @unchecked Sendable {
        var recorded: [(level: LogLevel, message: String)] = []

        func log(_ level: LogLevel, _ message: String, file: String, line: Int, function: String) {
            recorded.append((level, message))
        }
    }

    func testLoggingConvenienceMethods() {
        let logger = InMemoryLogger()
        logger.info("Hello info")
        logger.error("Something went wrong")

        XCTAssertEqual(logger.recorded.count, 2)
        XCTAssertEqual(logger.recorded[0].level, .info)
        XCTAssertEqual(logger.recorded[0].message, "Hello info")
        XCTAssertEqual(logger.recorded[1].level, .error)
    }

    func testLogLevelOrdering() {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        XCTAssertTrue(LogLevel.error < LogLevel.fault)
    }
}
