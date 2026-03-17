import SwiftUI
import WebKit

struct EdgeToEdgeWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        configuration.userContentController.addUserScript(Self.viewportScript)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        webView.scrollView.insetsLayoutMarginsFromSafeArea = false
        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static let viewportScript: WKUserScript = {
        let scriptSource = """
        (function() {
            var applyViewport = function() {
                var value = "width=device-width, initial-scale=1.0, viewport-fit=cover";
                var meta = document.querySelector('meta[name="viewport"]');
                if (!meta) {
                    meta = document.createElement("meta");
                    meta.setAttribute("name", "viewport");
                    document.head.appendChild(meta);
                }
                if (!meta.getAttribute("content") || meta.getAttribute("content").indexOf("viewport-fit=cover") === -1) {
                    meta.setAttribute("content", value);
                }
            };

            if (document.readyState === "loading") {
                document.addEventListener("DOMContentLoaded", applyViewport, { once: true });
            } else {
                applyViewport();
            }
        })();
        """

        return WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }()

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil else {
                return nil
            }

            webView.load(navigationAction.request)
            return nil
        }
    }
}
