import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    private var router: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        router = __MODULE_NAME__()
    }

    override func tearDown() {
        router = nil
        super.tearDown()
    }

    func testDeepLinkRouteParsing() {
        let url = URL(string: "myapp://product/detail/456?ref=share&user=john")!
        let route = DeepLinkRoute(url: url)

        XCTAssertEqual(route.host, "product")
        XCTAssertEqual(route.pathComponents, ["detail", "456"])
        XCTAssertEqual(route.queryItems["ref"], "share")
        XCTAssertEqual(route.queryItems["user"], "john")
    }

    func testRegisterAndHandleRoute() {
        let expectation = expectation(description: "Handler executed")
        router.registerHandler(forHost: "checkout") { route in
            XCTAssertEqual(route.pathComponents, ["123"])
            XCTAssertEqual(route.queryItems["promo"], "SAVE10")
            expectation.fulfill()
        }

        let url = URL(string: "myapp://checkout/123?promo=SAVE10")!
        let handled = router.handle(url)
        XCTAssertTrue(handled)

        wait(for: [expectation], timeout: 1.0)
    }

    func testUnhandledRouteReturnsFalse() {
        let url = URL(string: "myapp://unknown/path")!
        XCTAssertFalse(router.handle(url))
    }
}
