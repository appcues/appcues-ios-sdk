//
//  UIView+Capture.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/11/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

private var screenNameDateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
    return formatter
}()

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
    func screenCaptureDisplayName(at timestamp: Date) -> String {
        var name = ""
        if let window = self as? UIWindow,
           let root = window.rootViewController {
            name = root.viewControllerForName.displayName
        } else {
            name = String(describing: self.classForCoder)
        }

        name += " (\(screenNameDateFormatter.string(from: timestamp)))"
        return name
    }

    func screenshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 1)
        defer {
            UIGraphicsEndImageContext()
        }

        drawHierarchy(in: self.bounds, afterScreenUpdates: false)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
