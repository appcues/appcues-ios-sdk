//
//  ExperienceStepViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit
import SwiftUI

@available(iOS 13.0, *)
internal class ExperienceStepViewController: UIViewController {

    let viewModel: ExperienceStepViewModel
    let stepState: ExperienceData.StepState
    let notificationCenter: NotificationCenter?

    lazy var stepView = ExperienceStepView()
    var padding: NSDirectionalEdgeInsets {
        get { stepView.contentView.directionalLayoutMargins }
        set {
            stepView.contentView.directionalLayoutMargins = newValue

            NSLayoutConstraint.deactivate(paddingConstraints)
            paddingConstraints = [
                paddingLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: newValue.top),
                paddingLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: newValue.leading),
                paddingLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -newValue.trailing),
                paddingLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -newValue.bottom)
            ]
            NSLayoutConstraint.activate(paddingConstraints)
        }
    }

    private var paddingConstraints: [NSLayoutConstraint] = []
    let paddingLayoutGuide = UILayoutGuide()

    private let contentViewController: UIViewController

    var stickySpacing: UIEdgeInsets = .zero {
        didSet {
            stepView.scrollView.contentInset = stickySpacing
            // Ensure the main content starts below the top sticky content
            stepView.scrollView.contentOffset.y = -(stickySpacing.top + stepView.safeAreaInsets.top)
        }
    }

    init(viewModel: ExperienceStepViewModel, stepState: ExperienceData.StepState, notificationCenter: NotificationCenter? = nil) {
        self.viewModel = viewModel
        self.stepState = stepState
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
        view.addLayoutGuide(paddingLayoutGuide)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(contentViewController)
        stepView.contentView.addSubview(contentViewController.view)
        contentViewController.view.pin(to: stepView.contentView.layoutMarginsGuide)
        contentViewController.didMove(toParent: self)

        if let stickyTopContent = viewModel.step.stickyTopContent {
            decorateStickyContent(edge: .top, stickyTopContent)
        }
        if let stickyBottomContent = viewModel.step.stickyBottomContent {
            decorateStickyContent(edge: .bottom, stickyBottomContent)
        }

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
            width: contentSize.width,
            height: contentSize.height + stickySpacing.top + stickySpacing.bottom
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

        // Scroll the first responder into view.
        // This happens automatically in some cases (eg UITextField), but is a bit janky and this is smoother.
        // Also UITextView doesn't automatically scroll to visible as expected and so requires this implementation.
        if let targetView = view.firstResponder {
            let frameInScrollView = stepView.scrollView.convert(targetView.frame, from: targetView)
            stepView.scrollView.scrollRectToVisible(frameInScrollView, animated: false)
        }
    }

    private func decorateStickyContent(edge: ExperienceComponent.StackModel.StickyEdge, _ component: ExperienceComponent) {
        // Must have the environmentObject so any actions in the sticky content can be applied.
        let stickyContentVC = StickyHostingController(
            rootView: component.view
                .environmentObject(viewModel)
                .environmentObject(stepState)
        )

        // Add the stick content to the parent controller.
        addChild(stickyContentVC)
        view.addSubview(stickyContentVC.view)
        stickyContentVC.view.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = [
            stickyContentVC.view.leadingAnchor.constraint(equalTo: paddingLayoutGuide.leadingAnchor),
            stickyContentVC.view.trailingAnchor.constraint(equalTo: paddingLayoutGuide.trailingAnchor)
        ]

        switch edge {
        case .top:
            constraints.append(stickyContentVC.view.topAnchor.constraint(equalTo: paddingLayoutGuide.topAnchor))
        case .bottom:
            constraints.append(stickyContentVC.view.bottomAnchor.constraint(equalTo: paddingLayoutGuide.bottomAnchor))
        }

        NSLayoutConstraint.activate(constraints)

        stickyContentVC.didMove(toParent: self)

        // Pass sticky content size changes to the parent controller to update the insets.
        stickyContentVC.onSizeChange = { [weak self] size, _ in
            switch edge {
            case .top:
                self?.stickySpacing.top = size.height
                self?.stepView.scrollView.scrollIndicatorInsets.top = size.height + (self?.padding.top ?? 0)
            case .bottom:
                self?.stickySpacing.bottom = size.height
                self?.stepView.scrollView.scrollIndicatorInsets.bottom = size.height + (self?.padding.bottom ?? 0)
            }
        }
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

    /// HostingController that reports `frame` size changes.
    class StickyHostingController<Content: View>: AppcuesHostingController<Content> {

        var onSizeChange: ((CGSize, UIEdgeInsets) -> Void)?

        private var previousSize: CGSize = .zero

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            if view.frame.size != previousSize {
                onSizeChange?(view.frame.size, view.safeAreaInsets)
                previousSize = view.frame.size
            }
        }
    }
}

extension Notification.Name {
    internal static let shakeToRefresh = Notification.Name("shakeToRefresh")
}
