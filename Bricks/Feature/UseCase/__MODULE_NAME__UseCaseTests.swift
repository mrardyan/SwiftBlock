import XCTest
@testable import __APP_MODULE__

final class __MODULE_NAME__UseCaseTests: XCTestCase {
    func testUseCaseExecution() async throws {
        let useCase = Default__MODULE_NAME__UseCase()
        try await useCase.execute()
    }
}