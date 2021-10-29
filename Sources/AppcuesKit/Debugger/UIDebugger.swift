//
//  UIDebugger.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class UIDebugger {
    private var debugWindow: UIWindow?

    private let config: Appcues.Config

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
    }

    func show() {
        guard debugWindow == nil else { return }
        guard let windowScene = UIApplication.shared.activeWindowScenes.first else {
            config.logger.error("Could not open debugger")
            return
        }

        let panelViewController = UIViewController()
        panelViewController.view.backgroundColor = .secondarySystemBackground

        let rootViewController = DebugViewController(wrapping: panelViewController, dismissHandler: hide)
        debugWindow = DebugUIWindow(windowScene: windowScene, rootViewController: rootViewController)
    }

    func hide() {
        debugWindow?.isHidden = true
        debugWindow = nil
    }
}
