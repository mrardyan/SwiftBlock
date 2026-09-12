import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testWeightConversionsAndFormatting() throws {
        let w = try __MODULE_NAME__(grams: 2500)
        XCTAssertEqual(w.grams, 2500)
        XCTAssertEqual(w.kilograms, 2.5)
        XCTAssertEqual(w.formatted(locale: Locale(identifier: "en_US")), "2.5 kg")

        let wGram = try __MODULE_NAME__(grams: 450)
        XCTAssertEqual(wGram.formatted(locale: Locale(identifier: "en_US")), "450 g")
    }

    func testNegativeWeightThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(grams: -50)) { error in
            XCTAssertEqual(error as? WeightError, WeightError.negativeWeight(-50))
        }
    }
}
