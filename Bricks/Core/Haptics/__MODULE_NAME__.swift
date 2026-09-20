import UIKit

/// Kinds of haptic feedback supported by the engine.
public enum HapticFeedbackType: Sendable {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}

/// Unified haptic feedback engine wrapping `UIFeedbackGenerator`.
public enum __MODULE_NAME__ {
    public static func impact(_ type: HapticFeedbackType = .medium) {
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}