import Foundation

/// Defines standard interface for byte size formatting.
public protocol ByteFormatterProtocol: Sendable {
    func string(fromByteCount byteCount: Int64) -> String
}

/// Thread-safe byte count formatter singleton wrapping `ByteCountFormatter`.
public final class __MODULE_NAME__: @unchecked Sendable, ByteFormatterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let formatter: ByteCountFormatter

    public init(countStyle: ByteCountFormatter.CountStyle = .file) {
        let fmt = ByteCountFormatter()
        fmt.countStyle = countStyle
        fmt.allowedUnits = [.useAll]
        fmt.includesUnit = true
        self.formatter = fmt
    }

    /// Formats a byte count into human-readable string (e.g. "1.2 MB").
    public func string(fromByteCount byteCount: Int64) -> String {
        lock.lock()
        defer { lock.unlock() }
        return formatter.string(fromByteCount: byteCount)
    }
}
