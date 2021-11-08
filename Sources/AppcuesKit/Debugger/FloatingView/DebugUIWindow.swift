//
//  DebugUIWindow.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class DebugUIWindow: UIWindow {

    init(windowScene: UIWindowScene, rootViewController: UIViewController) {
        super.init(windowScene: windowScene)

        self.rootViewController = rootViewController
        windowLevel = .statusBar
        isHidden = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }

        if hitView == self {
            return rootViewController?.view.hitTest(point, with: event)
        }

        return hitView
    }
}


extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
