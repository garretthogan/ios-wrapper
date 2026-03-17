import SwiftUI

@main
struct WebShellApp: App {
    var body: some Scene {
        WindowGroup {
            WebShellRootView()
                .ignoresSafeArea(.all)
        }
    }
}
