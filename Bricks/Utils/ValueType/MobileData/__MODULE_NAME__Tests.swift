import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMobileDataConversionsAndFormatting() throws {
        let data = __MODULE_NAME__(gigabytes: 15.0)
        XCTAssertEqual(data.gigabytes, 15.0, accuracy: 0.01)
        XCTAssertFalse(data.formatted.isEmpty)

        let dataMB = __MODULE_NAME__(megabytes: 500)
        XCTAssertEqual(dataMB.megabytes, 500.0, accuracy: 0.01)
    }

    func testNegativeBytesThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(bytes: -100)) { error in
            XCTAssertEqual(error as? MobileDataError, MobileDataError.negativeBytes(-100))
        }
    }

    func testDataQuotaTypealiasCompatibility() {
        let quota: DataQuota = DataQuota(gigabytes: 10)
        XCTAssertEqual(quota.gigabytes, 10.0, accuracy: 0.01)
    }
}
