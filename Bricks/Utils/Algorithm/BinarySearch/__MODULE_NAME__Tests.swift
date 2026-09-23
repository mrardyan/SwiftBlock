import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testBinarySearchExactMatch() {
        let numbers = [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]

        XCTAssertEqual(numbers.binarySearch(for: 23), 5)
        XCTAssertEqual(numbers.binarySearch(for: 2), 0)
        XCTAssertEqual(numbers.binarySearch(for: 91), 9)
        XCTAssertNil(numbers.binarySearch(for: 40))
    }

    func testLowerBoundAndUpperBound() {
        let array = [1, 2, 4, 4, 4, 6, 7]

        // lowerBound: first element >= 4 (index 2)
        XCTAssertEqual(__MODULE_NAME__.lowerBound(in: array, for: 4), 2)

        // upperBound: first element > 4 (index 5)
        XCTAssertEqual(__MODULE_NAME__.upperBound(in: array, for: 4), 5)
    }
}
