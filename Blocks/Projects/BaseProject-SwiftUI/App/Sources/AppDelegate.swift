import UIKit

/// Application delegate handling app lifecycle and scene configuration.
class AppDelegate: NSObject, UIApplicationDelegate {
    /// Triggered after the application launch process finishes.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Perform initial application setup here
        return true
    }

    // MARK: - UISceneSession Lifecycle

    /// Configures scene session delegate for incoming window connections.
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
}
