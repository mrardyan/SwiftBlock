import Foundation
import Network

/// Network interface type.
public enum NetworkInterfaceType: Sendable, Equatable, Hashable {
    case wifi
    case cellular
    case ethernet
    case other
    case none
}

/// Network connectivity status snapshot.
public struct ConnectivityStatus: Sendable, Equatable {
    public let isConnected: Bool
    public let interfaceType: NetworkInterfaceType
    public let isExpensive: Bool
    public let isConstrained: Bool

    public init(isConnected: Bool, interfaceType: NetworkInterfaceType, isExpensive: Bool = false, isConstrained: Bool = false) {
        self.isConnected = isConnected
        self.interfaceType = interfaceType
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    public static let disconnected = ConnectivityStatus(isConnected: false, interfaceType: .none)
}

/// Protocol for network connectivity monitoring.
public protocol ConnectivityProtocol: Sendable {
{{#if concurrency == 'swift-concurrency'}}
    var status: ConnectivityStatus { get async }
    var isConnected: Bool { get async }
    func startMonitoring() async
    func stopMonitoring() async
    var statusUpdates: AsyncStream<ConnectivityStatus> { get async }
{{else}}
    var status: ConnectivityStatus { get }
    var isConnected: Bool { get }
    func startMonitoring()
    func stopMonitoring()
{{/if}}
}

{{#if concurrency == 'swift-concurrency'}}
/// Actor-isolated network reachability monitor wrapping NWPathMonitor.
public actor __MODULE_NAME__: ConnectivityProtocol {
    public static let shared = __MODULE_NAME__()

    private var _status: ConnectivityStatus = .disconnected
    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "com.swiftblock.connectivity")
    private let mockMode: Bool

    private let continuationLock = NSLock()
    private var continuations: [UUID: AsyncStream<ConnectivityStatus>.Continuation] = [:]

    public var status: ConnectivityStatus {
        _status
    }

    public var isConnected: Bool {
        _status.isConnected
    }

    /// An asynchronous stream emitting status updates upon network condition changes.
    public var statusUpdates: AsyncStream<ConnectivityStatus> {
        let current = _status
        return AsyncStream { continuation in
            let id = UUID()
            continuation.onTermination = { [weak self] _ in
                self?.removeContinuation(id: id)
            }
            continuation.yield(current)
            self.addContinuation(id: id, continuation: continuation)
        }
    }

    public init(mockStatus: ConnectivityStatus? = nil) {
        if let mock = mockStatus {
            self.mockMode = true
            self._status = mock
        } else {
            self.mockMode = false
        }
    }

    public func startMonitoring() {
        guard !mockMode else { return }
        guard monitor == nil else { return }

        let newMonitor = NWPathMonitor()
        newMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task {
                await self.updateStatus(with: path)
            }
        }
        newMonitor.start(queue: queue)
        self.monitor = newMonitor
    }

    public func stopMonitoring() {
        guard !mockMode else { return }
        monitor?.cancel()
        monitor = nil
    }

    public func updateMockStatus(_ newStatus: ConnectivityStatus) {
        guard mockMode else { return }
        _status = newStatus
        notifyContinuations(with: newStatus)
    }

    private func updateStatus(with path: NWPath) {
        let isConnected = path.status == .satisfied
        let interfaceType: NetworkInterfaceType

        if path.usesInterfaceType(.wifi) {
            interfaceType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            interfaceType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            interfaceType = .ethernet
        } else if isConnected {
            interfaceType = .other
        } else {
            interfaceType = .none
        }

        let newStatus = ConnectivityStatus(
            isConnected: isConnected,
            interfaceType: interfaceType,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained
        )

        _status = newStatus
        notifyContinuations(with: newStatus)
    }

    private nonisolated func addContinuation(id: UUID, continuation: AsyncStream<ConnectivityStatus>.Continuation) {
        continuationLock.lock()
        continuations[id] = continuation
        continuationLock.unlock()
    }

    private nonisolated func removeContinuation(id: UUID) {
        continuationLock.lock()
        continuations.removeValue(forKey: id)
        continuationLock.unlock()
    }

    private nonisolated func notifyContinuations(with status: ConnectivityStatus) {
        continuationLock.lock()
        let activeContinuations = Array(continuations.values)
        continuationLock.unlock()
        for continuation in activeContinuations {
            continuation.yield(status)
        }
    }
}
{{else}}
/// Thread-safe network reachability monitor wrapping NWPathMonitor.
public final class __MODULE_NAME__: @unchecked Sendable, ConnectivityProtocol {
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private var _status: ConnectivityStatus = .disconnected

    public var status: ConnectivityStatus {
        lock.lock()
        defer { lock.unlock() }
        return _status
    }

    public var isConnected: Bool {
        status.isConnected
    }

    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "com.swiftblock.connectivity")
    private let mockMode: Bool

    public init(mockStatus: ConnectivityStatus? = nil) {
        if let mock = mockStatus {
            self.mockMode = true
            self._status = mock
        } else {
            self.mockMode = false
        }
    }

    public func startMonitoring() {
        guard !mockMode else { return }
        lock.lock()
        defer { lock.unlock() }

        guard monitor == nil else { return }
        let newMonitor = NWPathMonitor()
        newMonitor.pathUpdateHandler = { [weak self] path in
            self?.updateStatus(with: path)
        }
        newMonitor.start(queue: queue)
        self.monitor = newMonitor
    }

    public func stopMonitoring() {
        guard !mockMode else { return }
        lock.lock()
        defer { lock.unlock() }

        monitor?.cancel()
        monitor = nil
    }

    public func updateMockStatus(_ newStatus: ConnectivityStatus) {
        guard mockMode else { return }
        lock.lock()
        defer { lock.unlock() }
        _status = newStatus
    }

    private func updateStatus(with path: NWPath) {
        let isConnected = path.status == .satisfied
        let interfaceType: NetworkInterfaceType

        if path.usesInterfaceType(.wifi) {
            interfaceType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            interfaceType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            interfaceType = .ethernet
        } else if isConnected {
            interfaceType = .other
        } else {
            interfaceType = .none
        }

        let newStatus = ConnectivityStatus(
            isConnected: isConnected,
            interfaceType: interfaceType,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained
        )

        lock.lock()
        _status = newStatus
        lock.unlock()
    }
}
{{/if}}
