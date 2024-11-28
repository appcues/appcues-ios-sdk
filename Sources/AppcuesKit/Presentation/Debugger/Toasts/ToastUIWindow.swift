//
//  ToastUIWindow.swift
//  AppcuesKit
//
//  Created by Matt on 2023-08-18.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

/// An empty UIViewController that will pass through all hit tests.
private class OverlayViewController: UIViewController {
    override func loadView() {
        view = HitTestingOverrideUIView(overrideApproach: .ignoreSelf)
    }
}

/// A transparent UIWindow that displays toast messages and handles the expected toast interactions.
internal class ToastUIWindow: UIWindow {

    private let toastTapRecognizer = UITapGestureRecognizer()
    lazy var toastView: ToastView = {
        let view = ToastView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    // used to schedule toast dismissal, and invalidate in cases where retry and new toast
    // are necessary
    private var toastDismissTimer: Task<Void, Never>?

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        self.rootViewController = OverlayViewController()
        windowLevel = .alert
        isHidden = false

        setupToasts()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        var hitView: UIView?
        var didTapToast = false

        for view in subviews.reversed() {
            // Convert to the subview's local coordinate system
            let convertedPoint = convert(point, to: view)
            if !view.point(inside: convertedPoint, with: event) {
                // Not inside the subview, keep looking
                continue
            }

            // If the subview can find a hit target, return that
            if let target = view.hitTest(convertedPoint, with: event) {
                hitView = target
                didTapToast = view == toastView
                break
            }
        }

        // any tap outside the toast when it is visible should hide toast
        // taps inside the toast are handled within the toast
        if toastView.alpha > 0 && !didTapToast {
            toastView.set(visibility: false, animated: true, completion: nil)
        }

        return hitView
    }

    private func setupToasts() {
        addSubview(toastView)

        NSLayoutConstraint.activate([
            toastView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor, constant: 25),
            toastView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor, constant: -25),
            toastView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -25),
            toastView.heightAnchor.constraint(greaterThanOrEqualToConstant: 64),
            toastView.heightAnchor.constraint(lessThanOrEqualToConstant: 128)
        ])

        toastTapRecognizer.addTarget(self, action: #selector(toastTapped))
        toastView.addGestureRecognizer(toastTapRecognizer)
    }

    @objc
    private func toastTapped(recognizer: UITapGestureRecognizer) {
        toastView.set(visibility: false, animated: true, completion: nil)
    }

    func showToast(_ toast: DebugToast) {
        // stop any pending dismiss when we are starting a new toast presentation
        // it will get reset to the desired timeout after the new toast is set visible
        toastDismissTimer?.cancel()

        toastView.configure(content: toast)
        toastView.set(visibility: true, animated: true) {
            // using a timer here so we can cancel and extend the toast on each subsequent retry attempt
            self.toastDismissTimer = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * toast.duration))
                if !Task.isCancelled {
                    self?.toastView.set(visibility: false, animated: true, completion: nil)
                }
            }
        }
    }
}
