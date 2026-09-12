import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMobileSMSFormattingAndAddition() throws {
        let sms = try __MODULE_NAME__(count: 500)
        XCTAssertEqual(sms.count, 500)
        XCTAssertEqual(sms.formatted, "500 SMS")

        let s1: __MODULE_NAME__ = 100
        let s2: __MODULE_NAME__ = 200
        let sum = s1 + s2
        XCTAssertEqual(sum.count, 300)
    }

    func testNegativeSMSQuotaThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(count: -5)) { error in
            XCTAssertEqual(error as? MobileSMSError, MobileSMSError.negativeCount(-5))
        }
    }

    func testSMSQuotaTypealiasCompatibility() {
        let quota: SMSQuota = 250
        XCTAssertEqual(quota.count, 250)
    }
}
