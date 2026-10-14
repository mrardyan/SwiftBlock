import Foundation

public struct FuzzyMatchResult<T>: Sendable where T: Sendable {
    public let item: T
    public let score: Int
    public let matchedIndices: [Int]

    public init(item: T, score: Int, matchedIndices: [Int]) {
        self.item = item
        self.score = score
        self.matchedIndices = matchedIndices
    }
}

/// Fast fuzzy string matching algorithm with score ranking.
///
/// Awards bonus points for consecutive character matches, word-boundary matches,
/// and start-of-string matches.
public enum __MODULE_NAME__: Sendable {
    /// Evaluates if `pattern` matches `target` and calculates match score.
    public static func score(pattern: String, target: String) -> (score: Int, matchedIndices: [Int])? {
        let p = Array(pattern.lowercased())
        let t = Array(target.lowercased())

        guard !p.isEmpty else { return (0, []) }
        guard p.count <= t.count else { return nil }

        var patternIdx = 0
        var targetIdx = 0
        var score = 0
        var matchedIndices: [Int] = []
        var consecutiveCount = 0

        while patternIdx < p.count && targetIdx < t.count {
            if p[patternIdx] == t[targetIdx] {
                matchedIndices.append(targetIdx)
                var charScore = 10

                // Word boundary / Prefix bonus
                if targetIdx == 0 {
                    charScore += 20
                } else {
                    let prevChar = target[target.index(target.startIndex, offsetBy: targetIdx - 1)]
                    if prevChar == " " || prevChar == "_" || prevChar == "-" || prevChar == "/" || prevChar == "." {
                        charScore += 15
                    }
                }

                // Consecutive match bonus
                charScore += (consecutiveCount * 5)
                consecutiveCount += 1

                score += charScore
                patternIdx += 1
            } else {
                consecutiveCount = 0
            }
            targetIdx += 1
        }

        guard patternIdx == p.count else { return nil }
        return (score, matchedIndices)
    }

    /// Filters and ranks a collection of items based on a fuzzy search query.
    public static func search<T: Sendable>(
        query: String,
        in items: [T],
        keyPath: @Sendable (T) -> String
    ) -> [FuzzyMatchResult<T>] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return items.map { FuzzyMatchResult(item: $0, score: 0, matchedIndices: []) }
        }

        var results: [FuzzyMatchResult<T>] = []
        for item in items {
            let text = keyPath(item)
            if let match = score(pattern: trimmed, target: text) {
                results.append(FuzzyMatchResult(item: item, score: match.score, matchedIndices: match.matchedIndices))
            }
        }

        return results.sorted { $0.score > $1.score }
    }
}
