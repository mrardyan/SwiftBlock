import Foundation
import CoreLocation

/// Errors thrown by location service operations.
public enum LocationError: Error, Equatable, Sendable {
    case permissionDenied
    case locationDisabled
    case timeout
    case unknown
}

/// Defines standard interface for CoreLocation operations.
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public protocol LocationServiceProtocol: Sendable {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization()
    func requestOneShotLocation() async throws -> CLLocation
}

/// Thread-safe CoreLocation manager wrapper.
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public final class __MODULE_NAME__: NSObject, @unchecked Sendable, LocationServiceProtocol, CLLocationManagerDelegate {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let locationManager: CLLocationManager
    private let lock = NSLock()

    private var oneShotContinuation: CheckedContinuation<CLLocation, Error>?

    public override init() {
        let manager = CLLocationManager()
        self.locationManager = manager
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Returns current location authorization status.
    public var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }

    /// Requests when-in-use authorization from the user.
    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Requests current device location asynchronously.
    /// - Returns: A `CLLocation` object representing the current location.
    public func requestOneShotLocation() async throws -> CLLocation {
        let status = authorizationStatus
        guard status != .denied && status != .restricted else {
            throw LocationError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            self.oneShotContinuation = continuation
            lock.unlock()

            self.locationManager.requestLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lock.lock()
        let continuation = oneShotContinuation
        oneShotContinuation = nil
        lock.unlock()

        if let location = locations.last {
            continuation?.resume(returning: location)
        } else {
            continuation?.resume(throwing: LocationError.unknown)
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lock.lock()
        let continuation = oneShotContinuation
        oneShotContinuation = nil
        lock.unlock()

        continuation?.resume(throwing: error)
    }
}
