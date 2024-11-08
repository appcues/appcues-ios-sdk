//
//  UIApplication+TopViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-14.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol TopControllerGetting {
    var hasActiveWindowScenes: Bool { get }

    func topViewController() -> UIViewController?
}

internal protocol URLOpening {
    var universalLinkHostAllowList: [String]? { get }

    func open(_ url: URL, completionHandler: @escaping (() -> Void))
    func open(potentialUniversalLink: URL) -> Bool
}

extension UIApplication: TopControllerGetting {

    @available(iOS 13.0, *)
    private var activeWindowScenes: [UIWindowScene] {
        self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
    }

    // Prefer the active window scene, but in the case where there's no active scene, use the one from the main app window.
    @available(iOS 13.0, *)
    var mainWindowScene: UIWindowScene? {
        activeWindowScenes.first ?? windows.first(where: { !$0.isAppcuesWindow })?.windowScene
    }

    // We expose this property because a unit test cannot init a UIWindowScene for mocking different states.
    var hasActiveWindowScenes: Bool {
        if #available(iOS 13.0, *) {
            return !activeWindowScenes.isEmpty
        } else {
            return false
        }
    }

    // Note: multitasking with two instances of the same app side by side will have both designated as `.foregroundActive`,
    // and as a result the returned window may not be the one expected.
    private var activeKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return self.activeWindowScenes
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return keyWindow
        }
    }

    func topViewController() -> UIViewController? {
        var window: UIWindow? = activeKeyWindow

        // swiftlint:disable:next force_unwrapping
        if window == nil || window!.isAppcuesWindow {
            window = UIApplication.shared.windows.first { !$0.isAppcuesWindow }
        }

        guard let rootViewController = window?.rootViewController else { return nil }
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

extension UIApplication: URLOpening {
    var universalLinkHostAllowList: [String]? {
        Bundle.main.object(forInfoDictionaryKey: "AppcuesUniversalLinkHostAllowList") as? [String]
    }

    func open(_ url: URL, completionHandler: @escaping (() -> Void)) {
        open(url, options: [:]) { _ in completionHandler() }
    }

    func open(potentialUniversalLink url: URL) -> Bool {
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = url
        // Pass some metadata to allow the `NSUserActivity` handler to know a link is coming from the Appcues SDK.
        userActivity.userInfo = [
            "referrer": "Appcues"
        ]
        return delegate?.application?(UIApplication.shared, continue: userActivity) { _ in } ?? false
    }
}
