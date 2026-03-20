import SwiftUI
import GameKit
import UIKit

@main
struct WebShellApp: App {
    @StateObject private var gameCenterService = GameCenterService()

    var body: some Scene {
        WindowGroup {
            WebShellRootView()
                .ignoresSafeArea(.all)
                .task {
                    await gameCenterService.authenticateIfNeeded()
                }
        }
    }
}

@MainActor
final class GameCenterService: ObservableObject {
    private var hasStartedAuthentication = false

    func authenticateIfNeeded() async {
        guard !hasStartedAuthentication else { return }
        hasStartedAuthentication = true

        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }

            if let error {
                // Fail quietly so Game Center issues never affect app stability.
                print("Game Center authentication failed: \(error.localizedDescription)")
                return
            }

            if let viewController {
                self.presentAuthenticationController(viewController)
                return
            }

            if GKLocalPlayer.local.isAuthenticated {
                print("Game Center authenticated: \(GKLocalPlayer.local.gamePlayerID)")
            } else {
                print("Game Center unavailable or declined by player.")
            }
        }
    }

    func reportAchievement(id: String, percentComplete: Double) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let boundedPercent = min(max(percentComplete, 0), 100)
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = boundedPercent
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error {
                print("Failed to report achievement \(id): \(error.localizedDescription)")
            }
        }
    }

    private func presentAuthenticationController(_ viewController: UIViewController) {
        guard let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            print("Game Center auth UI not presented: missing root view controller.")
            return
        }

        let presentingController = topViewController(from: rootViewController) ?? rootViewController
        presentingController.present(viewController, animated: true)
    }

    private func topViewController(from root: UIViewController) -> UIViewController? {
        var current = root
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }
}
