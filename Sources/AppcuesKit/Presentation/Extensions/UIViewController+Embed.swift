//
//  UIViewController+Embed.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIViewController {
    func embedChildViewController(
        _ childVC: UIViewController,
        inSuperview superview: UIView,
        respectLayoutMargins: Bool = false
    ) {
        addChild(childVC)
        superview.addSubview(childVC.view)
        if respectLayoutMargins {
            childVC.view.pin(to: superview.layoutMarginsGuide)
        } else {
            childVC.view.pin(to: superview)
        }
        childVC.didMove(toParent: self)
    }

    func unembedChildViewController(_ childVC: UIViewController) {
        guard childVC.parent == self else { return }
        childVC.willMove(toParent: nil)
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
}
