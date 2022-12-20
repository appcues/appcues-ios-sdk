//
//  ExperienceWrapperViewController.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperienceWrapperViewController<BodyView: ExperienceWrapperView>: UIViewController {

    lazy var bodyView = BodyView()

    private let experienceContainerViewController: UIViewController

    // Only set for bottom-aligned modals. Need access to the constant value for keyboard avoidance.
    var bottomConstraint: NSLayoutConstraint?

    init(wrapping containerViewController: UIViewController) {
        self.experienceContainerViewController = containerViewController
        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = bodyView
        embedChildViewController(experienceContainerViewController, inSuperview: bodyView.contentWrapperView, respectLayoutMargins: true)
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

    @discardableResult
    func configureStyle(_ style: ExperienceComponent.Style?) -> Self {
        bodyView.contentWrapperView.backgroundColor = UIColor(dynamicColor: style?.backgroundColor)
        bodyView.contentWrapperView.layer.cornerRadius = style?.cornerRadius ?? 0

        bodyView.contentWrapperView.layer.borderColor = UIColor(dynamicColor: style?.borderColor)?.cgColor
        if let borderWidth = CGFloat(style?.borderWidth) {
            bodyView.contentWrapperView.layer.borderWidth = borderWidth
            bodyView.contentWrapperView.layoutMargins = UIEdgeInsets(
                top: borderWidth,
                left: borderWidth,
                bottom: borderWidth,
                right: borderWidth)
        }

        bodyView.shadowLayer = CAShapeLayer(shadowModel: style?.shadow)

        switch style?.verticalAlignment {
        case "top":
            bodyView.contentWrapperView.topAnchor.constraint(equalTo: bodyView.safeAreaLayoutGuide.topAnchor).isActive = true
        case "bottom":
            let constraint = bodyView.contentWrapperView.bottomAnchor.constraint(equalTo: bodyView.safeAreaLayoutGuide.bottomAnchor)
            constraint.isActive = true
            bottomConstraint = constraint
        default:
            bodyView.contentWrapperView.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor).isActive = true
        }

        return self
    }

    @objc
    private func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let animationCurve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.bottomConstraint?.constant = 0

            if let animationDuration = animationDuration, let animationCurve = animationCurve {
                let options = UIView.AnimationOptions(rawValue: UInt(animationCurve << 16))
                UIView.animate(withDuration: animationDuration, delay: 0, options: options) {
                    self.view.layoutIfNeeded()
                }
            }
        } else {
            switch bodyView.contentWrapperView.keyboardAvoidanceStrategy(keyboardFrameInScreen: keyboardValue.cgRectValue) {
            case .scroll:
                // The ExperienceStepViewController handles this case and scrolls the content to avoid the keyboard.
                break
            case .move(let keyboardFrame):
                // Not enough room to scroll the firstResponder into view, so adjust the position of the dialogView.
                self.bottomConstraint?.constant = -keyboardFrame.height

                if let animationDuration = animationDuration, let animationCurve = animationCurve {
                    let options = UIView.AnimationOptions(rawValue: UInt(animationCurve << 16))
                    UIView.animate(withDuration: animationDuration, delay: 0, options: options) {
                        self.view.layoutIfNeeded()
                    }
                }
            }
        }
    }
}
