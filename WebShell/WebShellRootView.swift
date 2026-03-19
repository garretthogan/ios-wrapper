import SwiftUI

struct WebShellRootView: View {
    var body: some View {
        EdgeToEdgeWebView(url: AppConfig.startURL)
            .ignoresSafeArea(.all, edges: .all)
            .background(Color.black)
    }
}

private enum AppConfig {
    private static let defaultURLString = "http://locahost:5173"

    static var startURL: URL {
        if let rawValue = Bundle.main.object(forInfoDictionaryKey: "WebShellURL") as? String,
           let url = URL(string: rawValue),
           let scheme = url.scheme,
           ["http", "https"].contains(scheme.lowercased()) {
            return url
        }

        return URL(string: defaultURLString)!
    }
}
