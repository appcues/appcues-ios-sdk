//
//  UIApplication+TopViewController.swift
//  Appcues
//
//  Created by Matt on 2021-10-14.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIApplication {

    func topViewController() -> UIViewController? {
        let window = self.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }

        return topViewController(controller: window?.rootViewController)
    }

    private func topViewController(controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
