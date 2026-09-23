import Foundation

private final class TrieNode<Element: Hashable> {
    var children: [Element: TrieNode<Element>] = [:]
    var isEndOfWord: Bool = false
}

/// Prefix Tree (Trie) supporting $O(k)$ word insertion, search, prefix checks, and autocomplete suggestions.
public final class __MODULE_NAME__: @unchecked Sendable {
    private let root = TrieNode<Character>()
    private var wordCount: Int = 0
    private let lock = NSLock()

    /// Creates an empty Trie.
    public init() {}

    /// Creates a Trie pre-populated with a collection of words.
    public init(words: [String]) {
        for word in words {
            insert(word)
        }
    }

    /// Inserts a word into the Trie ($O(k)$ where $k$ is word length).
    public func insert(_ word: String) {
        lock.lock()
        defer { lock.unlock() }

        var current = root
        for char in word {
            if let next = current.children[char] {
                current = next
            } else {
                let newNode = TrieNode<Character>()
                current.children[char] = newNode
                current = newNode
            }
        }
        if !current.isEndOfWord {
            current.isEndOfWord = true
            wordCount += 1
        }
    }

    /// Checks if a complete word exists in the Trie ($O(k)$).
    public func contains(_ word: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let node = findNode(for: word) else { return false }
        return node.isEndOfWord
    }

    /// Checks if any word in the Trie starts with the given prefix ($O(k)$).
    public func startsWith(_ prefix: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        return findNode(for: prefix) != nil
    }

    /// Finds all words starting with the specified prefix (autocomplete / suggestions).
    public func words(matchingPrefix prefix: String) -> [String] {
        lock.lock()
        defer { lock.unlock() }

        guard let startNode = findNode(for: prefix) else { return [] }
        var results: [String] = []
        collectWords(from: startNode, currentPrefix: prefix, results: &results)
        return results.sorted()
    }

    /// Number of distinct words stored in the Trie.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return wordCount
    }

    // MARK: - Internals

    private func findNode(for string: String) -> TrieNode<Character>? {
        var current = root
        for char in string {
            guard let next = current.children[char] else { return nil }
            current = next
        }
        return current
    }

    private func collectWords(from node: TrieNode<Character>, currentPrefix: String, results: inout [String]) {
        if node.isEndOfWord {
            results.append(currentPrefix)
        }
        for (char, childNode) in node.children {
            collectWords(from: childNode, currentPrefix: currentPrefix + String(char), results: &results)
        }
    }
}
