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
        guard let hitView = super.hitTest(point, with: event), hitView != self else {
            return nil
        }

        // On iPad, there is a system view that wraps the rootView that can capture hits,
        // and we need to ignore that view to allow interaction with the underlying app
        // while the debug window is overlayed.
        if let rootView = rootViewController?.view, hitView.subviews.first == rootView {
            return nil
        }

        return hitView
    }
}
