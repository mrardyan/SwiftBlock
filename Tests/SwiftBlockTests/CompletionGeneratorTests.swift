import Foundation
@testable import SwiftBlockCore
import XCTest

final class CompletionGeneratorTests: XCTestCase {
    func testGenerateZshCompletion() {
        let script = CompletionGenerator.generate(for: .zsh)
        XCTAssertTrue(script.contains("#compdef swiftblock"))
        XCTAssertTrue(script.contains("snap:Snap a foundation"))
        XCTAssertTrue(script.contains("--flavor="))
        XCTAssertTrue(script.contains("--with-optional="))
        XCTAssertTrue(script.contains("clean-feature"))
    }

    func testGenerateBashCompletion() {
        let script = CompletionGenerator.generate(for: .bash)
        XCTAssertTrue(script.contains("# bash completion for swiftblock"))
        XCTAssertTrue(script.contains("complete -F _swiftblock_completions swiftblock"))
        XCTAssertTrue(script.contains("snap"))
    }

    func testGenerateFishCompletion() {
        let script = CompletionGenerator.generate(for: .fish)
        XCTAssertTrue(script.contains("# fish completion for swiftblock"))
        XCTAssertTrue(script.contains("complete -c swiftblock"))
        XCTAssertTrue(script.contains("-l flavor"))
    }
}
