//
//  DeepLinkNavigator.swift
//  AppcuesExample
//
//  Created by Matt on 2022-03-04.
//

import UIKit
import AppcuesKit

// NOTE: This deep link implementation should not be taken as an example of best practices. It's not particularly scalable,
// it's coupled to the specific view controller hierarchy of the app, and uses segues which can cause runtime crashes.
class DeepLinkNavigator: AppcuesNavigationDelegate {

    /// Link destinations
    struct DeepLink {
        enum Destination {
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
        }

        let destination: Destination
        let experienceID: String?

        init?(url: URL) {
            guard url.scheme == "appcues-example" else { return nil }

            switch url.host?.lowercased() {
            case "signin": destination = .signIn
            case "events": destination = .events
            case "profile": destination = .profile
            case "group": destination = .group
            default: return nil
            }

            experienceID = url.experienceID
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

    var scene: UIScene?

    func handle(openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handle(url: URLContexts.first?.url, completion: nil)
    }

    func navigate(to url: URL, completion: @escaping (Bool) -> Void) {
        handle(url: url, completion: completion)
    }

    private func handle(url: URL?, completion: ((Bool) -> Void)?) {
        guard let url = url else {
            // no valid URL given, cannot navigate
            completion?(false)
            return
        }

        guard let target = DeepLink(url: url) else {
            // the link was not a known deep link for this application, so pass along off to OS to handle
            UIApplication.shared.open(url, options: [:]) { success in completion?(success) }
            return
        }

        guard let windowScene = scene as? UIWindowScene,
            let window = windowScene.windows.first(where: { $0.isKeyWindow }),
            let origin = AppScreen(rootController: window.rootViewController)
        else {
            // cannot find the screen information to navigate, fail navigation
            completion?(false)
            return
        }

        let handler = { self.navigate(from: origin, to: target, in: window, completion: completion) }

        if let scene = scene {
            switch scene.activationState {
            case .foregroundActive:
                handler()
            case .foregroundInactive, .background, .unattached:
                fallthrough
            @unknown default:
                storedHandler = handler
            }
        } else {
            // cases where no scene was given, such as links originating in active Appcues
            // experiences that are passed in through the AppcuesNavigationDelegate
            handler()
        }
    }

    private func navigate(from origin: AppScreen, to target: DeepLink, in window: UIWindow, completion: ((Bool) -> Void)?) {

        switch (origin, target.destination) {
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
            if let targetIndex = target.destination.tabIndex {
                window.tabController?.selectedIndex = targetIndex
            }
        }

        if let experienceID = target.experienceID {
            Appcues.shared.show(experienceID: experienceID) { success, _ in
                // we'll use the final success value from showing the experience for the overall success
                // of the deep link routing, in this case
                completion?(success)
            }
        } else {
            completion?(true)
        }
    }

    func didBecomeActive() {
        storedHandler?()
        storedHandler = nil
    }
}

private extension URL {
    // Support for showing Appcues content by ID in the "experience" query parameter
    var experienceID: String? {
        let urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        return urlComponents?.queryItems?.first { $0.name == "experience" }?.value
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
