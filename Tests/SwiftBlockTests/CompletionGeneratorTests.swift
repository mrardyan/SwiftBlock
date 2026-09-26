import Foundation
import Testing
@testable import SwiftBlockCore

struct CompletionGeneratorTests {

    @Test func generateZshCompletion() {
        let script = CompletionGenerator.generate(for: .zsh)
        #expect(script.contains("#compdef swiftblock"))
        #expect(script.contains("snap:Snap a foundation"))
        #expect(script.contains("--flavor="))
        #expect(script.contains("--with-optional="))
        #expect(script.contains("clean-feature"))
    }

    @Test func generateBashCompletion() {
        let script = CompletionGenerator.generate(for: .bash)
        #expect(script.contains("# bash completion for swiftblock"))
        #expect(script.contains("complete -F _swiftblock_completions swiftblock"))
        #expect(script.contains("snap"))
    }

    @Test func generateFishCompletion() {
        let script = CompletionGenerator.generate(for: .fish)
        #expect(script.contains("# fish completion for swiftblock"))
        #expect(script.contains("complete -c swiftblock"))
        #expect(script.contains("-l flavor"))
    }
}
