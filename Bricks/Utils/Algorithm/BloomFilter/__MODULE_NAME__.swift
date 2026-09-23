import Foundation

/// Space-efficient probabilistic data structure for set membership testing.
///
/// Guarantees **zero false negatives**:
/// - If `contains` returns `false`, the element is definitely not in the set.
/// - If `contains` returns `true`, the element is probably in the set (with configurable false positive probability).
public struct __MODULE_NAME__<Element: Hashable & Sendable>: Sendable {
    public let size: Int
    public let hashCount: Int
    private var bitArray: [Bool]

    /// Initializes a BloomFilter with optimal size and hash count for `expectedElements` and `falsePositiveRate`.
    /// - Parameters:
    ///   - expectedElements: Number of items expected to be inserted.
    ///   - falsePositiveRate: Target false positive probability (e.g., 0.01 for 1%).
    public init(expectedElements: Int, falsePositiveRate: Double = 0.01) {
        let n = Double(max(1, expectedElements))
        let p = max(0.0001, min(0.9999, falsePositiveRate))

        // m = - (n * ln(p)) / (ln(2)^2)
        let m = Int(ceil(- (n * log(p)) / pow(log(2.0), 2.0)))
        // k = (m / n) * ln(2)
        let k = max(1, Int(round((Double(m) / n) * log(2.0))))

        self.size = max(64, m)
        self.hashCount = k
        self.bitArray = Array(repeating: false, count: self.size)
    }

    /// Inserts an element into the bloom filter.
    public mutating func insert(_ element: Element) {
        for index in hashIndices(for: element) {
            bitArray[index] = true
        }
    }

    /// Tests if an element is possibly in the bloom filter.
    public func contains(_ element: Element) -> Bool {
        for index in hashIndices(for: element) {
            if !bitArray[index] {
                return false
            }
        }
        return true
    }

    private func hashIndices(for element: Element) -> [Int] {
        var hasher1 = Hasher()
        hasher1.combine(element)
        let h1 = hasher1.finalize()

        var hasher2 = Hasher()
        hasher2.combine(element)
        hasher2.combine(0x9e3779b97f4a7c15 as UInt64)
        let h2 = hasher2.finalize()

        var indices: [Int] = []
        indices.reserveCapacity(hashCount)

        for i in 0..<hashCount {
            // Double hashing scheme: h(i) = (h1 + i * h2) mod size
            let combined = (Int64(h1) &+ Int64(i) &* Int64(h2))
            let positive = combined < 0 ? -(combined % Int64(size)) : (combined % Int64(size))
            indices.append(Int(positive))
        }

        return indices
    }
}
