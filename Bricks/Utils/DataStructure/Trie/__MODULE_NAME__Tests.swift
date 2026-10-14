import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testTrieInsertionAndSearch() {
        let trie = __MODULE_NAME__()

        trie.insert("apple")
        trie.insert("app")
        trie.insert("application")
        trie.insert("banana")

        XCTAssertTrue(trie.contains("apple"))
        XCTAssertTrue(trie.contains("app"))
        XCTAssertFalse(trie.contains("appl")) // Prefix only, not a word
        XCTAssertFalse(trie.contains("orange"))

        XCTAssertTrue(trie.startsWith("appl"))
        XCTAssertTrue(trie.startsWith("ban"))
        XCTAssertFalse(trie.startsWith("ora"))
    }

    func testTrieAutocompletePrefixMatching() {
        let trie = __MODULE_NAME__(words: ["cat", "caterpillar", "category", "cattle", "dog"])

        let catWords = trie.words(matchingPrefix: "cat")
        XCTAssertEqual(catWords, ["cat", "category", "caterpillar", "cattle"])

        let doWords = trie.words(matchingPrefix: "do")
        XCTAssertEqual(doWords, ["dog"])

        let nonExistent = trie.words(matchingPrefix: "xyz")
        XCTAssertTrue(nonExistent.isEmpty)
    }
}
