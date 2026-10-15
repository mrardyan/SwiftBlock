import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
{{#if concurrency == 'swift-concurrency'}}
    func testDeepLinkRouteParsing() {
        let url = URL(string: "myapp://product/detail/456?ref=share&user=john")!
        let route = DeepLinkRoute(url: url)

        XCTAssertEqual(route.host, "product")
        XCTAssertEqual(route.pathComponents, ["detail", "456"])
        XCTAssertEqual(route.queryItems["ref"], "share")
        XCTAssertEqual(route.queryItems["user"], "john")
    }

    func testRegisterAndHandleRoute() async {
        let router = __MODULE_NAME__()
        let expectation = expectation(description: "Handler executed")
        await router.registerHandler(forHost: "checkout") { route in
            XCTAssertEqual(route.pathComponents, ["123"])
            XCTAssertEqual(route.queryItems["promo"], "SAVE10")
            expectation.fulfill()
        }

        let url = URL(string: "myapp://checkout/123?promo=SAVE10")!
        let handled = await router.handle(url)
        XCTAssertTrue(handled)

        wait(for: [expectation], timeout: 1.0)
    }

    func testUnhandledRouteReturnsFalse() async {
        let router = __MODULE_NAME__()
        let url = URL(string: "myapp://unknown/path")!
        let handled = await router.handle(url)
        XCTAssertFalse(handled)
    }
{{else}}
    func testDeepLinkRouteParsing() {
        let url = URL(string: "myapp://product/detail/456?ref=share&user=john")!
        let route = DeepLinkRoute(url: url)

        XCTAssertEqual(route.host, "product")
        XCTAssertEqual(route.pathComponents, ["detail", "456"])
        XCTAssertEqual(route.queryItems["ref"], "share")
        XCTAssertEqual(route.queryItems["user"], "john")
    }

    func testRegisterAndHandleRoute() {
        let router = __MODULE_NAME__()
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
        let router = __MODULE_NAME__()
        let url = URL(string: "myapp://unknown/path")!
        XCTAssertFalse(router.handle(url))
    }
{{/if}}
}
