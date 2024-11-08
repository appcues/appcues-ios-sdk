//
//  ModalContextManager.swift
//  AppcuesKit
//
//  Created by Matt on 2024-09-25.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ModalContextManager {
    var presentingWindow: AppcuesUIWindow?

    func present(viewController: UIViewController, useSameWindow: Bool = false, completion: (() -> Void)?) throws {
        guard !useSameWindow else {
            try presentInSameWindow(viewController: viewController, completion: completion)
            return
        }

        guard let windowScene = UIApplication.shared.mainWindowScene else {
            throw AppcuesTraitError(description: "No main window scene")
        }

        let window = AppcuesUIWindow(windowScene: windowScene)

        guard let rootViewController = window.rootViewController else {
            throw AppcuesTraitError(description: "No root view controller")
        }

        rootViewController.present(viewController, animated: true, completion: completion)

        presentingWindow = window
    }

    private func presentInSameWindow(viewController: UIViewController, completion: (() -> Void)?) throws {
        guard let topViewController = UIApplication.shared.topViewController() else {
            throw AppcuesTraitError(description: "No top VC found")
        }

        topViewController.present(viewController, animated: true, completion: completion)
    }

    func remove(viewController: UIViewController, completion: (() -> Void)?) {
        viewController.dismiss(animated: true) {
            self.presentingWindow = nil
            completion?()
        }
    }
}

@available(iOS 13.0, *)
extension ModalContextManager {
    class AppcuesUIWindow: UIWindow {
        override init(windowScene: UIWindowScene) {
            super.init(windowScene: windowScene)

            rootViewController = AppcuesWindowRootViewController()
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

            // Ignore UITransitionViews to allow interaction with the underlying app while the window is overlayed.
            if String(describing: type(of: hitView)) == "UITransitionView" {
                return nil
            }

            return hitView
        }
    }

    class AppcuesWindowRootViewController: UIViewController {
        init() {
            super.init(nibName: nil, bundle: nil)

            // Ensure this root view isn't eligible for a hitTest
            // (any ViewController it presents will be though)
            view.alpha = 0
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
