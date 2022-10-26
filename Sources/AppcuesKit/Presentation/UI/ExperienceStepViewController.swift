//
//  ExperienceStepViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperienceStepViewController: UIViewController {

    let viewModel: ExperienceStepViewModel
    let notificationCenter: NotificationCenter?

    lazy var stepView = ExperienceStepView()
    var padding: NSDirectionalEdgeInsets {
        get { stepView.contentView.directionalLayoutMargins }
        set { stepView.contentView.directionalLayoutMargins = newValue }
    }

    private let contentViewController: UIViewController

    init(viewModel: ExperienceStepViewModel, stepState: ExperienceData.StepState, notificationCenter: NotificationCenter? = nil) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter

        let rootView = ExperienceStepRootView(rootView: viewModel.step.content.view, viewModel: viewModel, stepState: stepState)
        self.contentViewController = AppcuesHostingController(rootView: rootView)
        self.contentViewController.view.backgroundColor = .clear

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = stepView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(contentViewController)
        stepView.contentView.addSubview(contentViewController.view)
        contentViewController.view.pin(to: stepView.contentView.layoutMarginsGuide)
        contentViewController.didMove(toParent: self)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        let contentSize = stepView.scrollView.contentSize
        preferredContentSize = CGSize(
            width: contentSize.width + additionalSafeAreaInsets.left + additionalSafeAreaInsets.right,
            height: contentSize.height + additionalSafeAreaInsets.top + additionalSafeAreaInsets.bottom
        )
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            notificationCenter?.post(name: .shakeToRefresh, object: self)
        }
    }

    @objc
    private func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        if notification.name == UIResponder.keyboardWillHideNotification {
            stepView.scrollView.contentInset.bottom = 0
        } else {
            let keyboardFrameInScreen = keyboardValue.cgRectValue
            let keyboardFrameInView = stepView.scrollView.convert(keyboardFrameInScreen, from: view.window)
            let intersection = stepView.scrollView.bounds.intersection(keyboardFrameInView)

            stepView.scrollView.contentInset.bottom = intersection.height - view.safeAreaInsets.bottom
        }

        stepView.scrollView.scrollIndicatorInsets = stepView.scrollView.contentInset
    }
}

@available(iOS 13.0, *)
extension ExperienceStepViewController {
    class ExperienceStepView: UIView {
        lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            view.translatesAutoresizingMaskIntoConstraints = false
            // Force a consistent safe area behavior regardless of whether the content scrolls
            view.contentInsetAdjustmentBehavior = .always

            // For text input blocks, we want scrolling the modal content to be able to dismiss the keyboard.
            view.keyboardDismissMode = .interactive
            return view
        }()

        lazy var contentView: UIView = {
            let view = UIView()
            view.directionalLayoutMargins = .zero
            return view
        }()

        // When nested inside the carousel traits collection view, the left and right safe area insets get doubled applied.
        // This zeros out those values to achieve the desired layout.
        override var safeAreaInsets: UIEdgeInsets {
            UIEdgeInsets(top: super.safeAreaInsets.top, left: 0, bottom: super.safeAreaInsets.bottom, right: 0)
        }

        init() {
            super.init(frame: .zero)

            addSubview(scrollView)
            scrollView.addSubview(contentView)
            contentView.pin(to: scrollView)
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

                contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension Notification.Name {
    internal static let shakeToRefresh = Notification.Name("shakeToRefresh")
}
