//
//  ModalContextManager.swift
//  AppcuesKit
//
//  Created by Matt on 2024-09-25.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

internal class ModalContextManager {
    @MainActor
    private var presentingWindow: AppcuesUIWindow?

    init() {
        // no-op
    }

    @MainActor
    func present(viewController: UIViewController, useSameWindow: Bool = false) async throws {
        guard !useSameWindow else {
            return try await presentInSameWindow(viewController: viewController)
        }

        guard let windowScene = UIApplication.shared.mainWindowScene else {
            throw AppcuesTraitError(description: "No main window scene")
        }

        let window = AppcuesUIWindow(windowScene: windowScene)

        guard let rootViewController = window.rootViewController else {
            throw AppcuesTraitError(description: "No root view controller")
        }

        await withCheckedContinuation { continuation in
            rootViewController.present(viewController, animated: true) {
                continuation.resume()
            }
        }

        presentingWindow = window
    }

    @MainActor
    private func presentInSameWindow(viewController: UIViewController) async throws {
        guard let topViewController = UIApplication.shared.topViewController() else {
            throw AppcuesTraitError(description: "No top VC found")
        }

        await withCheckedContinuation { continuation in
            topViewController.present(viewController, animated: true) {
                continuation.resume()
            }
        }
    }

    @MainActor
    func remove(viewController: UIViewController) async {
        await withCheckedContinuation { continuation in
            viewController.dismiss(animated: true) {
                continuation.resume()
            }
        }
        // Ensure the window is removed from the hierarchy even if something outside the SDK has a reference to it
        self.presentingWindow?.windowScene = nil
        self.presentingWindow = nil
    }
}

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
