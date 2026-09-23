import Foundation

/// Binary Search algorithms and Collection extensions.
///
/// Provides $O(\log n)$ search, lower-bound, and upper-bound lookups on sorted random-access collections.
public enum __MODULE_NAME__: Sendable {
    /// Finds the index of an element in a sorted collection using a custom comparator.
    public static func search<C: RandomAccessCollection>(
        in collection: C,
        matching: (C.Element) -> ComparisonResult
    ) -> C.Index? where C.Index == Int {
        var low = 0
        var high = collection.count - 1

        while low <= high {
            let mid = low + (high - low) / 2
            let index = collection.index(collection.startIndex, offsetBy: mid)
            let cmp = matching(collection[index])

            switch cmp {
            case .orderedSame:
                return index
            case .orderedAscending: // Target is greater than current element
                low = mid + 1
            case .orderedDescending: // Target is smaller than current element
                high = mid - 1
            }
        }
        return nil
    }

    /// Finds the first index containing an element greater than or equal to `target` ($O(\log n)$).
    public static func lowerBound<C: RandomAccessCollection>(
        in collection: C,
        for target: C.Element
    ) -> C.Index where C.Element: Comparable, C.Index == Int {
        var low = 0
        var high = collection.count

        while low < high {
            let mid = low + (high - low) / 2
            let index = collection.index(collection.startIndex, offsetBy: mid)
            if collection[index] < target {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return collection.index(collection.startIndex, offsetBy: low)
    }

    /// Finds the first index containing an element strictly greater than `target` ($O(\log n)$).
    public static func upperBound<C: RandomAccessCollection>(
        in collection: C,
        for target: C.Element
    ) -> C.Index where C.Element: Comparable, C.Index == Int {
        var low = 0
        var high = collection.count

        while low < high {
            let mid = low + (high - low) / 2
            let index = collection.index(collection.startIndex, offsetBy: mid)
            if collection[index] <= target {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return collection.index(collection.startIndex, offsetBy: low)
    }
}

// MARK: - RandomAccessCollection Convenience Extensions
extension RandomAccessCollection where Element: Comparable, Index == Int {
    /// Performs binary search for an exact match.
    public func binarySearch(for target: Element) -> Index? {
        __MODULE_NAME__.search(in: self) { element in
            if element == target {
                return .orderedSame
            } else if element < target {
                return .orderedAscending
            } else {
                return .orderedDescending
            }
        }
    }
}
