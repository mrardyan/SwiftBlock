import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testInvalidURIReturnsNil() async {
        let loader = __MODULE_NAME__()
        let url = URL(string: "https://invalid-non-existent-domain-12345.invalid/image.png")!
        let image = await loader.image(from: url)
        XCTAssertNil(image)
    }

    func testClearCacheDoesNotThrow() {
        let loader = __MODULE_NAME__()
        loader.clearCache()
    }
}