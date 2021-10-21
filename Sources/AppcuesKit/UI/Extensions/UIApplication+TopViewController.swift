//
//  UIApplication+TopViewController.swift
//  Appcues
//
//  Created by Matt on 2021-10-14.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIApplication {

    // Note: multitasking with two instances of the same app side by side will have both designated as `.foregroundActive`,
    // and as a result the returned window may not be the one expected.
    private var activeKeyWindow: UIWindow? {
        self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
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
