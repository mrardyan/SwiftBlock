import Foundation

public enum TestFramework: String, Codable, CaseIterable {
    case xctest = "xctest"
    case swiftTesting = "swift-testing"

    public var displayName: String {
        switch self {
        case .xctest: return "XCTest"
        case .swiftTesting: return "Swift Testing (@Test)"
        }
    }
}

public struct TestFrameworkConverter {
    public static func convert(_ content: String, target: TestFramework) -> String {
        guard target == .swiftTesting else {
            return content
        }

        var result = content

        // 1. Framework import
        result = result.replacingOccurrences(of: "import XCTest", with: "import Testing")

        // 2. Test class declaration -> @Suite struct declaration
        let classRegexPattern = #"final\s+class\s+(\w+)\s*:\s*XCTestCase"#
        if let regex = try? NSRegularExpression(pattern: classRegexPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "@Suite struct $1")
        }

        // 3. Test functions: func testFoo() -> @Test func testFoo()
        let funcRegexPattern = #"func\s+(test\w*)\s*\("#
        if let regex = try? NSRegularExpression(pattern: funcRegexPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "@Test func $1(")
        }

        // 4. Assertions conversion:
        // XCTAssertEqual(a, b) -> #expect(a == b)
        let assertEqualPattern = #"XCTAssertEqual\(([^,]+),\s*([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: assertEqualPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "#expect($1 == $2)")
        }

        // XCTAssertTrue(a) -> #expect(a)
        let assertTruePattern = #"XCTAssertTrue\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: assertTruePattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "#expect($1)")
        }

        // XCTAssertFalse(a) -> #expect(!($1))
        let assertFalsePattern = #"XCTAssertFalse\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: assertFalsePattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "#expect(!($1))")
        }

        // XCTAssertNil(a) -> #expect(a == nil)
        let assertNilPattern = #"XCTAssertNil\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: assertNilPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "#expect($1 == nil)")
        }

        // XCTAssertNotNil(a) -> #expect(a != nil)
        let assertNotNilPattern = #"XCTAssertNotNil\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: assertNotNilPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "#expect($1 != nil)")
        }

        // XCTFail(msg) -> Issue.record(msg)
        let failPattern = #"XCTFail\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: failPattern, options: []) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "Issue.record($1)")
        }

        return result
    }
}
