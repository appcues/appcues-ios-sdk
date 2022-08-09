//
//  DeepLinkNavigator.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2022-03-04.
//

import UIKit
import AppcuesKit

// NOTE: This deep link implementation should not be taken as an example of best practices. It's not particularly scalable,
// it's coupled to the specific view controller hierarchy of the app, and uses segues which can cause runtime crashes.
class DeepLinkNavigator {

    /// Link destinations
    enum DeepLink {
        case signIn
        case events
        case profile
        case group

        var tabIndex: Int? {
            // needs to match Main.storyboard
            switch self {
            case .signIn: return nil
            case .events: return 0
            case .profile: return 1
            case .group: return 2
            }
        }

        init?(host: String?) {
            switch host?.lowercased() {
            case "signin": self = .signIn
            case "events": self = .events
            case "profile": self = .profile
            case "group": self = .group
            default: return nil
            }
        }
    }

    /// Link origins
    enum AppScreen {
        case signIn(SignInViewController)
        case events(EventsViewController)
        case profile(ProfileViewController)
        case group(GroupViewController)

        var controller: UIViewController {
            switch self {
            case .signIn(let controller): return controller
            case .events(let controller): return controller
            case .profile(let controller): return controller
            case .group(let controller): return controller
            }
        }

        init?(rootController: UIViewController?) {
            var screen: AppScreen?
            if let navigationController = rootController as? UINavigationController {
                screen = AppScreen(rootController: navigationController.topViewController)
            } else if let tabController = rootController as? UITabBarController {
                screen = AppScreen(rootController: tabController.selectedViewController)
            } else {
                if let signInController = rootController as? SignInViewController {
                    screen = AppScreen(rootController: rootController?.presentedViewController) ?? .signIn(signInController)
                } else if let eventsController = rootController as? EventsViewController {
                    screen = .events(eventsController)
                } else if let profileController = rootController as? ProfileViewController {
                    screen = .profile(profileController)
                } else if let groupController = rootController as? GroupViewController {
                    screen = .group(groupController)
                }
            }

            if let screen = screen {
                self = screen
            } else {
                return nil
            }
        }
    }

    private var storedHandler: (() -> Void)?

    func handle(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard
            let url = URLContexts.first?.url,
            url.scheme == "appcues-example",
            let target = DeepLink(host: url.host)
        else { return }

        let handler = {
            guard
                let windowScene = scene as? UIWindowScene,
                let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                let origin = AppScreen(rootController: window.rootViewController)
            else {
                return
            }

            switch (origin, target) {
            case (.signIn, .signIn), (.events, .events), (.profile, .profile), (.group, .group):
                // Linking to current screen, no changes needed
                break
            case (_, .signIn):
                origin.controller.dismiss(animated: false)
            case (.signIn(let controller), _):
                // NOTE: segue identifier needs to match Main.storyboard
                controller.performSegue(withIdentifier: "signin", sender: nil)
                fallthrough
            case (_, _):
                if let targetIndex = target.tabIndex {
                    window.tabController?.selectedIndex = targetIndex
                }
            }

            // Show Appcues content by ID in the "experience" query parameter
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let appcuesExperienceID = urlComponents?.queryItems?.first(where: { $0.name == "experience" })?.value {
                Appcues.shared.show(experienceID: appcuesExperienceID)
            }
        }

        switch scene.activationState {
        case .foregroundActive:
            handler()
        case .foregroundInactive, .background, .unattached:
            fallthrough
        @unknown default:
            storedHandler = handler
        }
    }

    func didBecomeActive() {
        storedHandler?()
        storedHandler = nil
    }
}

extension UIWindow {
    var tabController: UITabBarController? {
        visibleViewController(controller: rootViewController)
    }

    private func visibleViewController<T: UIViewController>(controller: UIViewController?) -> T? {
        if let controller = controller as? T {
            return controller
        }
        if let navigationController = controller as? UINavigationController {
            return visibleViewController(controller: navigationController.topViewController)
        }
        if let tabController = controller as? UITabBarController {
            return visibleViewController(controller: tabController.selectedViewController)
        }
        if let presentedController = controller?.presentedViewController {
            return visibleViewController(controller: presentedController)
        }

        return nil
    }
}
