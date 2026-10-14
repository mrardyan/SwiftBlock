import Foundation
import LocalAuthentication

/// Supported biometric hardware types.
public enum BiometricType: String, Sendable {
    case faceID = "Face ID"
    case touchID = "Touch ID"
    case opticID = "Optic ID"
    case none = "None"
}

/// Defines standard interface for biometric authentication operations.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public protocol BiometricAuthManagerProtocol: Sendable {
    var biometricType: BiometricType { get }
    func canEvaluateBiometrics() -> Bool
    func authenticate(reason: String) async throws -> Bool
}

/// Thread-safe biometric authentication manager wrapping `LAContext`.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class __MODULE_NAME__: @unchecked Sendable, BiometricAuthManagerProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    public init() {}

    /// Returns the available biometric hardware type on the current device.
    public var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Checks whether the device is capable of biometric authentication.
    public func canEvaluateBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Evaluates biometric authentication prompt asynchronously.
    /// - Parameter reason: Display message explaining why authentication is requested.
    /// - Returns: `true` if authentication succeeded, `false` otherwise.
    public func authenticate(reason: String = "Authenticate to access secure data.") async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let err = error {
                throw err
            }
            return false
        }

        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
}
