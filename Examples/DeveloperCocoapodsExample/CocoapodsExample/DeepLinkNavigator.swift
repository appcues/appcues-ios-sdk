//
//  DeepLinkNavigator.swift
//  AppcuesCocoapodsExample
//
//  Created by Matt on 2022-03-04.
//

import UIKit
import SafariServices
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
            case embed

            init?(path: String?) {
                switch path?.lowercased() {
                case "signin": self = .signIn
                case "events": self = .events
                case "profile": self = .profile
                case "group": self = .group
                case "embed": self = .embed
                default: return nil
                }
            }

            var tabIndex: Int? {
                // needs to match Main.storyboard
                switch self {
                case .signIn: return nil
                case .events: return 0
                case .profile: return 1
                case .group: return 2
                case .embed: return 3
                }
            }
        }

        let destination: Destination
        let experienceID: String?

        init?(url: URL) {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
            if url.scheme == "appcues-example" {
                // try to handle as a scheme link
                guard let destination = Destination(path: url.host) else { return nil }
                self.destination = destination
                self.experienceID = components.experienceID
            } else if url.host == "appcues-mobile-links.netlify.app" {
                // try to handle as a universal link to our associated domain
                let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                guard let destination = Destination(path: path) else { return nil }
                self.destination = destination
                self.experienceID = components.experienceID
            } else {
                // not a supported deep link URL
                return nil
            }
        }
    }

    /// Link origins
    enum AppScreen {
        case signIn(SignInViewController)
        case events(EventsViewController)
        case profile(ProfileViewController)
        case group(GroupViewController)
        case embed(EmbedViewController)

        var controller: UIViewController {
            switch self {
            case .signIn(let controller): return controller
            case .events(let controller): return controller
            case .profile(let controller): return controller
            case .group(let controller): return controller
            case .embed(let controller): return controller
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
                } else if let embedController = rootController as? EmbedViewController {
                    screen = .embed(embedController)
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

    // conforming to AppcuesNavigationDelegate for navigation requests coming from the Appcues SDK
    func navigate(to url: URL, openExternally: Bool, completion: @escaping (Bool) -> Void) {
        handle(url: url, openExternally: openExternally, completion: completion)
    }

    // called by scheme links or universal links attempting to deep link into our application
    // returns `true` if the link was a known deep link destination and was sent for processing, `false`
    // if an unknown link and not handled. The completion block indicates full link processing completed async.
    @discardableResult
    func handle(url: URL?, openExternally: Bool = false, completion: ((Bool) -> Void)? = nil) -> Bool {
        guard let url = url else {
            // no valid URL given, cannot navigate
            completion?(false)
            return false
        }

        guard let windowScene = scene as? UIWindowScene,
            let window = windowScene.windows.first(where: { !$0.isAppcuesWindow }),
            let origin = AppScreen(rootController: window.rootViewController)
        else {
            // cannot find the screen information to navigate, fail navigation
            completion?(false)
            return false
        }

        guard let target = DeepLink(url: url) else {
            // the link was not a known deep link for this application, so pass along off to OS to handle
            if openExternally {
                UIApplication.shared.open(url, options: [:]) { success in completion?(success) }
            } else {
                if let topController = window.topViewController() {
                    topController.present(SFSafariViewController(url: url), animated: true) { completion?(true) }
                } else {
                    completion?(false)
                }
            }
            return false
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

        return true
    }

    private func navigate(from origin: AppScreen, to target: DeepLink, in window: UIWindow, completion: ((Bool) -> Void)?) {

        switch (origin, target.destination) {
        case (.signIn, .signIn), (.events, .events), (.profile, .profile), (.group, .group), (.embed, .embed):
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

private extension URLComponents {
    // Support for showing Appcues content by ID in the "experience" query parameter
    var experienceID: String? {
        return queryItems?.first { $0.name == "experience" }?.value
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

    func topViewController() -> UIViewController? {
        guard let rootViewController = rootViewController else { return nil }
        return topViewController(controller: rootViewController)
    }

    private func topViewController(controller: UIViewController) -> UIViewController {
        if let navigationController = controller as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            if !visibleViewController.isBeingDismissed {
                return topViewController(controller: visibleViewController)
            } else if let topStack = navigationController.viewControllers.last {
                // This gets the VC under what is being dismissed
                return topViewController(controller: topStack)
            } else {
                return topViewController(controller: visibleViewController)
            }
        }
        if let tabController = controller as? UITabBarController,
           let selected = tabController.selectedViewController {
            return topViewController(controller: selected)
        }
        if let presented = controller.presentedViewController, !presented.isBeingDismissed {
            return topViewController(controller: presented)
        }
        return controller
    }
}
