import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct StringToIntTransformer: __MODULE_NAME__ {
        func transform(_ source: String) throws -> Int {
            guard let intVal = Int(source) else {
                throw NSError(domain: "test", code: 400)
            }
            return intVal
        }
    }

    struct IntToDoubleMultiplier: __MODULE_NAME__ {
        let multiplier: Double
        func transform(_ source: Int) throws -> Double {
            Double(source) * multiplier
        }
    }

    func testPipedTransformationChain() throws {
        let step1 = StringToIntTransformer()
        let step2 = IntToDoubleMultiplier(multiplier: 2.5)

        let pipeline = step1.pipe(step2)

        let result = try pipeline.transform("10")
        XCTAssertEqual(result, 25.0)
    }

    func testTransformAll() throws {
        let step = StringToIntTransformer()
        let results = try step.transformAll(["1", "2", "3"])
        XCTAssertEqual(results, [1, 2, 3])
    }
}
