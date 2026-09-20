import StoreKit
import UIKit

/// StoreKit rating prompt and App Store helpers.
public enum __MODULE_NAME__ {
    /// Presents the system rating prompt if conditions allow.
    public static func requestReview() {
        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
        #endif
    }

    /// Opens the app's App Store page for the given Apple ID.
    public static func openAppStorePage(appID: String) {
        #if os(iOS)
        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)") else { return }
        UIApplication.shared.open(url)
        #endif
    }
}