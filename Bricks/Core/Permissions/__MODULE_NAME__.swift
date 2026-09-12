import Foundation
import AVFoundation
import Photos
import UserNotifications
import CoreLocation

/// System permission resource types.
public enum SystemPermissionType: String, Sendable, CaseIterable {
    case camera = "Camera"
    case photoLibrary = "Photo Library"
    case microphone = "Microphone"
    case notifications = "Notifications"
    case location = "Location"
}

/// Unified authorization status representation.
public enum PermissionStatus: String, Sendable {
    case authorized = "Authorized"
    case denied = "Denied"
    case restricted = "Restricted"
    case notDetermined = "Not Determined"
}

/// Defines standard interface for unified system permissions management.
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public protocol SystemPermissionManagerProtocol: Sendable {
    func status(for permission: SystemPermissionType) -> PermissionStatus
    func requestPermission(for permission: SystemPermissionType) async -> PermissionStatus
    func requestPermissions(_ permissions: [SystemPermissionType]) async -> [SystemPermissionType: PermissionStatus]
}

/// Thread-safe unified system permission manager.
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
public final class __MODULE_NAME__: @unchecked Sendable, SystemPermissionManagerProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    public init() {}

    /// Checks authorization status for the specified permission type.
    public func status(for permission: SystemPermissionType) -> PermissionStatus {
        switch permission {
        case .camera:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return mapAVStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        case .photoLibrary:
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return mapPhotoStatus(status)
        case .location:
            let status = CLLocationManager().authorizationStatus
            return mapLocationStatus(status)
        case .notifications:
            return .notDetermined
        }
    }

    /// Requests authorization for the specified system permission type asynchronously.
    public func requestPermission(for permission: SystemPermissionType) async -> PermissionStatus {
        switch permission {
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        case .microphone:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            return granted ? .authorized : .denied
        case .photoLibrary:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return mapPhotoStatus(status)
        case .notifications:
            do {
                let center = UNUserNotificationCenter.current()
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                return granted ? .authorized : .denied
            } catch {
                return .denied
            }
        case .location:
            return status(for: .location)
        }
    }

    /// Requests authorization for multiple permission types sequentially to prevent iOS dialog collisions.
    /// - Parameter permissions: List of permission types to request.
    /// - Returns: Dictionary mapping each permission type to its resulting `PermissionStatus`.
    public func requestPermissions(_ permissions: [SystemPermissionType]) async -> [SystemPermissionType: PermissionStatus] {
        var results: [SystemPermissionType: PermissionStatus] = [:]
        for permission in permissions {
            let result = await requestPermission(for: permission)
            results[permission] = result
        }
        return results
    }

    private func mapAVStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private func mapPhotoStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private func mapLocationStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}
