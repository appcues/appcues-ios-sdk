//
//  DialogContainerViewController.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class DialogContainerViewController: UIViewController {

    lazy var containerView = DialogContainerView()

    private let dialogViewController: UIViewController

    init(wrapping dialogViewController: UIViewController) {
        self.dialogViewController = dialogViewController
        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }

    // Only set for bottom-aligned modals. Need access to the constant value for keyboard avoidance.
    var bottomConstraint: NSLayoutConstraint?

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = containerView
        embedChildViewController(dialogViewController, inSuperview: containerView.dialogView, respectLayoutMargins: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

    func configureStyle(_ style: ExperienceComponent.Style?) -> Self {
        containerView.dialogView.backgroundColor = UIColor(dynamicColor: style?.backgroundColor)
        containerView.dialogView.layer.cornerRadius = style?.cornerRadius ?? 0

        containerView.dialogView.layer.borderColor = UIColor(dynamicColor: style?.borderColor)?.cgColor
        if let borderWidth = CGFloat(style?.borderWidth) {
            containerView.dialogView.layer.borderWidth = borderWidth
            containerView.dialogView.layoutMargins = UIEdgeInsets(
                top: borderWidth,
                left: borderWidth,
                bottom: borderWidth,
                right: borderWidth)
        }

        containerView.shadowLayer = CAShapeLayer(shadowModel: style?.shadow)

        switch style?.verticalAlignment {
        case "top":
            containerView.dialogView.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor).isActive = true
        case "bottom":
            let constraint = containerView.dialogView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
            constraint.isActive = true
            bottomConstraint = constraint
        default:
            containerView.dialogView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        }

        return self
    }

    @objc
    private func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.bottomConstraint?.constant = 0
        } else {
            switch containerView.dialogView.keyboardAvoidanceStrategy(keyboardFrameInScreen: keyboardValue.cgRectValue) {
            case .scroll:
                // The ExperienceStepViewController handles this case and scrolls the content to avoid the keyboard.
                break
            case .move(let keyboardFrame):
                // Not enough room to scroll the firstResponder into view, so adjust the position of the dialogView.
                self.bottomConstraint?.constant = -keyboardFrame.height
            }
        }
    }
}
