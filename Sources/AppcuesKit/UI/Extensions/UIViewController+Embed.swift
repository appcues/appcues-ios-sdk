//
//  UIViewController+Embed.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIViewController {
    func embedChildViewController(_ childVC: UIViewController, inSuperview superview: UIView) {
        addChild(childVC)
        superview.addSubview(childVC.view)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childVC.view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            childVC.view.topAnchor.constraint(equalTo: superview.topAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
        childVC.didMove(toParent: self)
    }
}
