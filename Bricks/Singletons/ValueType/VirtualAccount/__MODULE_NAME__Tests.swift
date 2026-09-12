import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testVirtualAccountFormattingAndValidation() throws {
        let va = try __MODULE_NAME__(number: "880123456789", bankName: "BCA")
        XCTAssertEqual(va.number, "880123456789")
        XCTAssertEqual(va.bankName, "BCA")
        XCTAssertEqual(va.formattedGrouped, "8801 2345 6789")
    }

    func testInvalidLengthThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(number: "123")) { error in
            XCTAssertEqual(error as? VirtualAccountError, VirtualAccountError.invalidLength("123"))
        }
    }
}
