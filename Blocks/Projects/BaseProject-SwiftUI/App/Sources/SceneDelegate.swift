import UIKit

/// Scene delegate managing UI lifecycle for multi-window scene sessions.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// Active window reference.
    var window: UIWindow?

    /// Called when the scene is connecting to a new window session.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

