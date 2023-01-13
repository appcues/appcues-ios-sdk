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

extension UIView {

    var appcuesSelector: ElementSelector? {
        return ElementSelector(
            accessibilityIdentifier: accessibilityIdentifier,
            description: accessibilityLabel,
            tag: tag != 0 ? "\(self.tag)" : nil,
            id: nil)
    }

    var screenCaptureDisplayName: String {
        var name = ""
        if let window = self as? UIWindow,
           let root = window.rootViewController {
            name = root.viewControllerForName.displayName
        } else {
            name = String(describing: self.classForCoder)
        }

        name += " (\(screenNameDateFormatter.string(from: Date())))"
        return name
    }

    func screenshot() -> Data? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 1)
        defer {
            UIGraphicsEndImageContext()
        }

        drawHierarchy(in: self.bounds, afterScreenUpdates: false)

        return UIGraphicsGetImageFromCurrentImageContext()?.jpegData(compressionQuality: 0.5)
    }

    func captureLayout() -> Capture.View? {
        return self.asCaptureView(in: self.bounds)
    }

    private func asCaptureView(in bounds: CGRect) -> Capture.View? {
        let absolutePosition = self.convert(self.bounds, to: nil)

        guard absolutePosition.intersects(bounds) else { return nil }

        let children: [Capture.View] = self.subviews.compactMap {
            guard !$0.isHidden else { return nil }
            return $0.asCaptureView(in: bounds)
        }

        return Capture.View(
            x: absolutePosition.origin.x,
            y: absolutePosition.origin.y,
            width: absolutePosition.width,
            height: absolutePosition.height,
            type: "\(type(of: self))",
            selector: appcuesSelector,
            children: children.isEmpty ? nil : children)
    }
}
