//
//  DebugModalViewController.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/30/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit
import SwiftUI

// A UIViewController that can be used to host any SwiftUI modal content to be presented,
// and handle keyboard avoidance, if necessary.
//
// This is similar to the structure of the ExperienceWrapperViewController - providing
// the backdrop - and the ExperienceStepViewController centered within - providing the scroll
// container where the hosted SwiftUI content resides. However, this is a more specific and
// reduced implementation that is decoupled from Experience step content and data.
internal class DebugModalViewController<Content: View>: UIViewController {

    lazy var containerView = DebugModalWrapperView()

    private lazy var preferredHeightConstraint: NSLayoutConstraint = {
        var constraint = containerView.scrollView.heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = true
        return constraint
    }()

    private let contentViewController: UIViewController

    init(rootView: Content) {
        self.contentViewController = AppcuesHostingController(rootView: rootView)
        self.contentViewController.view.backgroundColor = .clear

        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = containerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        embedChildViewController(contentViewController, inSuperview: containerView.contentView, respectLayoutMargins: true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        // If the current child controller changes it's preferred size, propagate that this controller's view.
        preferredHeightConstraint.constant = container.preferredContentSize.height
    }

    @objc
    private func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        if notification.name == UIResponder.keyboardWillHideNotification {
            containerView.scrollView.contentInset.bottom = 0
        } else {
            let keyboardFrameInScreen = keyboardValue.cgRectValue
            let keyboardFrameInView = containerView.scrollView.convert(keyboardFrameInScreen, from: view.window)
            let intersection = containerView.scrollView.bounds.intersection(keyboardFrameInView)

            containerView.scrollView.contentInset.bottom = intersection.height
        }

        containerView.scrollView.scrollIndicatorInsets = containerView.scrollView.contentInset

        // Scroll the first responder into view.
        // This happens automatically in some cases (eg UITextField), but is a bit janky and this is smoother.
        // Also UITextView doesn't automatically scroll to visible as expected and so requires this implementation.
        if let targetView = view.firstResponder {
            let frameInScrollView = containerView.scrollView.convert(targetView.frame, from: targetView)
            containerView.scrollView.scrollRectToVisible(frameInScrollView, animated: false)
        }
    }
}

extension DebugModalViewController {
    internal class DebugModalWrapperView: UIView {
        let backdropView: UIView = {
            let view = UIView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = UIColor.label.withAlphaComponent(0.33)
            return view
        }()

        lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            view.translatesAutoresizingMaskIntoConstraints = false
            // Force a consistent safe area behavior regardless of whether the content scrolls
            view.contentInsetAdjustmentBehavior = .always
            // For text input blocks, we want scrolling the modal content to be able to dismiss the keyboard.
            view.keyboardDismissMode = .interactive
            view.layer.cornerRadius = 6.0
            view.backgroundColor = UIColor.systemBackground
            return view
        }()

        lazy var contentView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.directionalLayoutMargins = .zero
            return view
        }()

        required init() {
            super.init(frame: .zero)

            backgroundColor = .clear

            scrollView.addSubview(contentView)

            addSubview(backdropView)
            addSubview(scrollView)

            contentView.pin(to: scrollView)
            backdropView.pin(to: self)

            NSLayoutConstraint.activate([
                scrollView.centerYAnchor.constraint(equalTo: centerYAnchor),
                scrollView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),
                scrollView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor),
                contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
