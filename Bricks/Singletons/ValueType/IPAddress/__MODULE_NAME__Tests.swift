import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testIPv4ValidationAndProperties() throws {
        let ip = try __MODULE_NAME__(rawValue: "192.168.1.1")
        XCTAssertEqual(ip.version, .v4)
        XCTAssertTrue(ip.isPrivate)
        XCTAssertFalse(ip.isLoopback)

        let loopback = try __MODULE_NAME__(rawValue: "127.0.0.1")
        XCTAssertTrue(loopback.isLoopback)

        let publicIP: __MODULE_NAME__ = "8.8.8.8"
        XCTAssertFalse(publicIP.isPrivate)
        XCTAssertFalse(publicIP.isLoopback)
    }

    func testIPv6Validation() throws {
        let ip = try __MODULE_NAME__(rawValue: "2001:0db8:85a3:0000:0000:8a2e:0370:7334")
        XCTAssertEqual(ip.version, .v6)

        let loopback = try __MODULE_NAME__(rawValue: "::1")
        XCTAssertEqual(loopback.version, .v6)
        XCTAssertTrue(loopback.isLoopback)
    }

    func testInvalidIP() {
        XCTAssertThrowsError(try __MODULE_NAME__(rawValue: "256.1.1.1"))
        XCTAssertThrowsError(try __MODULE_NAME__(rawValue: "1.2.3"))
        XCTAssertThrowsError(try __MODULE_NAME__(rawValue: "not-an-ip"))
    }
}
