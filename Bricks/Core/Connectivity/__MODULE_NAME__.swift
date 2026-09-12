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
    var status: ConnectivityStatus { get }
    var isConnected: Bool { get }
    func startMonitoring()
    func stopMonitoring()
}

/// Network reachability monitor wrapping NWPathMonitor.
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
