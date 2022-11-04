//
//  UIApplication+TopViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-14.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal protocol TopControllerGetting {
    func topViewController() -> UIViewController?
}
internal protocol URLOpening {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler: ((Bool) -> Void)?)
    func open(potentialUniversalLink: URL) -> Bool
}

extension UIApplication: TopControllerGetting {

    @available(iOS 13.0, *)
    var activeWindowScenes: [UIWindowScene] {
        self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
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
        guard let rootViewController = activeKeyWindow?.rootViewController else { return nil }
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
