//
//  UIView+Capture.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/11/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

private extension UIViewController {
    var viewControllerForName: UIViewController {
        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.viewControllerForName
        } else if let tabBarController = self as? UITabBarController,
                  let selected = tabBarController.selectedViewController {
            return selected.viewControllerForName
        } else if let presented = self.presentedViewController {
            return presented.viewControllerForName
        } else {
            guard children.count == 1 else { return self }
            return children[0].viewControllerForName
        }
    }
}

internal extension UIView {
    func screenCaptureDisplayName() -> String {
        let name: String
        if let window = self as? UIWindow, let root = window.rootViewController {
            name = root.viewControllerForName.displayName
        } else {
            name = String(describing: self.classForCoder)
        }

        return name
    }

    func screenshot() -> UIImage? {
        guard frame.size != .zero else { return nil }

        let renderer = UIGraphicsImageRenderer(size: frame.size)
        return renderer.image { context in
            drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        }
    }
}
