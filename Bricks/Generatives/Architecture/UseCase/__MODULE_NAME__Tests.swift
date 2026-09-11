import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__UseCaseTests: XCTestCase {
    func testUseCaseExecution() async throws {
        let useCase = Default__MODULE_NAME__UseCase()
        let result = try await useCase.execute()
        XCTAssertTrue(result)
    }
}
