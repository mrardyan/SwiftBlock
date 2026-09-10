import SwiftUI
#if canImport(Core)
import Core
#endif

/// Main application entry point struct for __PROJECT_NAME__.
@main
struct __PROJECT_NAME__App: App {
    /// AppDelegate integration adaptor.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Initializes app instance and configures Core foundation modules if present.
    init() {
        #if canImport(Core)
        CoreModule.configure()
        #endif
    }

    /// Application scene window group hierarchy.
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
