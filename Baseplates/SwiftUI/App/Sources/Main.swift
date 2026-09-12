import SwiftUI
#if canImport(Core)
import Core
#endif

/// Main application entry point.
@main
struct __PROJECT_NAME__App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        #if canImport(Core)
        if #available(iOS 15.0, macOS 12.0, *) {
            CoreModule.configure()
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
