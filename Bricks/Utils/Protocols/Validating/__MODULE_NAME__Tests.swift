import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testAndCombinator() {
        let nonEmpty = AnyValidator<String>({ !$0.isEmpty }, failureMessage: "Field is empty")
        let minLength = AnyValidator<String>({ $0.count >= 5 }, failureMessage: "Too short")

        let combined = nonEmpty.and(minLength)

        XCTAssertTrue(combined.isValid("Hello World"))
        XCTAssertFalse(combined.isValid(""))
        XCTAssertFalse(combined.isValid("Hi"))
    }

    func testOrCombinator() {
        let isZero = AnyValidator<Int>({ $0 == 0 }, failureMessage: "Not zero")
        let isPositiveEven = AnyValidator<Int>({ $0 > 0 && $0 % 2 == 0 }, failureMessage: "Not positive even")

        let combined = isZero.or(isPositiveEven)

        XCTAssertTrue(combined.isValid(0))
        XCTAssertTrue(combined.isValid(4))
        XCTAssertFalse(combined.isValid(3))
        XCTAssertFalse(combined.isValid(-2))
    }

    func testNotCombinator() {
        let isBanned = AnyValidator<String>({ $0.lowercased() == "admin" }, failureMessage: "Is admin")
        let notBanned = isBanned.not(failureMessage: "Username 'admin' is prohibited")

        XCTAssertTrue(notBanned.isValid("alice"))
        XCTAssertFalse(notBanned.isValid("admin"))
    }
}
