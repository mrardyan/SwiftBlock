import Foundation

/// Tracks pagination state (page, page size, and whether more pages remain).
public struct __MODULE_NAME__: Sendable, Equatable {
    public var page: Int
    public let pageSize: Int
    public var hasMore: Bool
    public var total: Int?

    public init(page: Int = 0, pageSize: Int = 20, hasMore: Bool = true, total: Int? = nil) {
        self.page = page
        self.pageSize = pageSize
        self.hasMore = hasMore
        self.total = total
    }

    /// A cursor for the next page.
    public var nextPage: __MODULE_NAME__ {
        var next = self
        next.page += 1
        return next
    }

    /// Updates state after a page of results is received.
    public mutating func apply(count: Int, total: Int? = nil) {
        if let total = total {
            self.total = total
            hasMore = (page + 1) * pageSize < total
        } else {
            hasMore = count >= pageSize
        }
    }
}