import SwiftUI
#if canImport(Core)
import Core
#endif

@main
struct __PROJECT_NAME__App: App {
    // AppDelegate support
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        #if canImport(Core)
        CoreModule.configure()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

