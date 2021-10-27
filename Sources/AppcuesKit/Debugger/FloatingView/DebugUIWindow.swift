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
        return rootViewController?.view.hitTest(point, with: event)
    }
}
