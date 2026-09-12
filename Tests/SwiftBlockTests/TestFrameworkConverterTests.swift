import XCTest
@testable import SwiftBlockCore

final class TestFrameworkConverterTests: XCTestCase {
    func testConvertXCTestToSwiftTesting() {
        let input = """
        import XCTest
        @testable import Core
        @testable import App

        final class NetworkTests: XCTestCase {
            func testSuccessfulFetch() async throws {
                let status = 200
                XCTAssertEqual(status, 200)
                XCTAssertTrue(status > 0)
                XCTAssertFalse(status == 404)
                XCTAssertNil(nil)
                XCTAssertNotNil(status)
            }
        }
        """

        let converted = TestFrameworkConverter.convert(input, target: .swiftTesting)

        XCTAssertTrue(converted.contains("import Testing"))
        XCTAssertTrue(converted.contains("@Suite struct NetworkTests"))
        XCTAssertTrue(converted.contains("@Test func testSuccessfulFetch() async throws"))
        XCTAssertTrue(converted.contains("#expect(status == 200)"))
        XCTAssertTrue(converted.contains("#expect(status > 0)"))
        XCTAssertTrue(converted.contains("#expect(!(status == 404))"))
        XCTAssertTrue(converted.contains("#expect(nil == nil)"))
        XCTAssertTrue(converted.contains("#expect(status != nil)"))
    }

    func testPreserveXCTestWhenTargetIsXCTest() {
        let input = """
        import XCTest
        final class NetworkTests: XCTestCase {
            func testFetch() {
                XCTAssertEqual(1, 1)
            }
        }
        """

        let converted = TestFrameworkConverter.convert(input, target: .xctest)

        XCTAssertEqual(input, converted)
    }
}
