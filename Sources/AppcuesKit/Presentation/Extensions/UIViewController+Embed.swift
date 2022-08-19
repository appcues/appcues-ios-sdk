//
//  UIViewController+Embed.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIViewController {
    func embedChildViewController(_ childVC: UIViewController, inSuperview superview: UIView, margins: NSDirectionalEdgeInsets = .zero) {
        addChild(childVC)
        superview.addSubview(childVC.view)
        childVC.view.pin(to: superview, margins: margins)
        childVC.didMove(toParent: self)
    }

    func unembedChildViewController(_ childVC: UIViewController) {
        guard childVC.parent == self else { return }
        childVC.willMove(toParent: nil)
        childVC.view.removeFromSuperview()
        childVC.removeFromParent()
    }
}
