import Foundation

/// Levenshtein Distance & String Similarity algorithm.
///
/// Computes the minimum number of single-character edits (insertions, deletions, substitutions)
/// required to change one string into another using memory-optimized dynamic programming $O(\min(M, N))$ space.
public enum __MODULE_NAME__: Sendable {
    /// Calculates the edit distance between two strings.
    public static func distance(_ source: String, _ target: String) -> Int {
        let s = Array(source)
        let t = Array(target)
        let m = s.count
        let n = t.count

        guard m > 0 else { return n }
        guard n > 0 else { return m }

        // Optimize memory to O(min(M, N))
        var previousRow = Array(0...n)
        var currentRow = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            currentRow[0] = i
            for j in 1...n {
                let cost = s[i - 1] == t[j - 1] ? 0 : 1
                currentRow[j] = min(
                    previousRow[j] + 1,       // deletion
                    currentRow[j - 1] + 1,    // insertion
                    previousRow[j - 1] + cost // substitution
                )
            }
            previousRow = currentRow
        }

        return previousRow[n]
    }

    /// Calculates normalized similarity score between 0.0 (completely distinct) and 1.0 (identical).
    public static func similarity(_ source: String, _ target: String) -> Double {
        if source == target { return 1.0 }
        let maxLength = max(source.count, target.count)
        guard maxLength > 0 else { return 1.0 }

        let dist = distance(source, target)
        return 1.0 - (Double(dist) / Double(maxLength))
    }
}
