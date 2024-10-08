//
//  ExperienceWrapperViewController.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import SwiftUI

@available(iOS 13.0, *)
internal class ExperienceWrapperViewController<BodyView: ExperienceWrapperView>: UIViewController, UIViewControllerTransitioningDelegate {

    lazy var bodyView = BodyView()

    private let experienceContainerViewController: UIViewController

    // Values for pan gesture handling
    private var allowedEdges: Set<DragDirection.Edge> = []
    private var initialOffset: CGPoint = .zero
    private var initialCenter: CGPoint = .zero

    // Only set for bottom-aligned modals. Need access to the constant value for keyboard avoidance.
    var bottomConstraint: NSLayoutConstraint?

    private var slideAnimationController: ExperienceWrapperSlideAnimator?

    init(wrapping containerViewController: UIViewController) {
        self.experienceContainerViewController = containerViewController
        super.init(nibName: nil, bundle: nil)
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
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @discardableResult
    func configureStyle(_ style: ExperienceComponent.Style?, transition: AppcuesModalTrait.Transition = .fade) -> Self {
        bodyView.contentWrapperView.backgroundColor = UIColor(dynamicColor: style?.backgroundColor)

        bodyView.applyCornerRadius(CGFloat(style?.cornerRadius))
        bodyView.applyBorder(color: UIColor(dynamicColor: style?.borderColor), width: CGFloat(style?.borderWidth))

        if let shadowModel = style?.shadow {
            bodyView.shadowWrappingView.layer.shadowColor = UIColor(dynamicColor: shadowModel.color)?.cgColor
            bodyView.shadowWrappingView.layer.shadowOpacity = 1
            bodyView.shadowWrappingView.layer.shadowRadius = shadowModel.radius
            bodyView.shadowWrappingView.layer.shadowOffset = CGSize(width: shadowModel.x, height: shadowModel.y)
            bodyView.shadowWrappingView.layer.cornerRadius = style?.cornerRadius ?? 0
        }

        bodyView.setNeedsLayout()

        configureConstraints(style)

        switch transition {
        case .fade:
            modalTransitionStyle = .crossDissolve
            modalPresentationStyle = .overFullScreen
        case let .slide(edge):
            modalPresentationStyle = .custom
            transitioningDelegate = self
            let animator = ExperienceWrapperSlideAnimator(view: bodyView, edge: edge)
            slideAnimationController = animator

            allowedEdges = DragDirection.allowedEdges(
                horizontalAlignment: HorizontalAlignment(string: style?.horizontalAlignment) ?? .center,
                verticalAlignment: VerticalAlignment(string: style?.verticalAlignment) ?? .center
            )

            let panRecognizer = UIPanGestureRecognizer()
            panRecognizer.addTarget(self, action: #selector(slideoutPanned(recognizer:)))
            bodyView.contentWrapperView.addGestureRecognizer(panRecognizer)
        }

        return self
    }

    private func configureConstraints(_ style: ExperienceComponent.Style?) {
        let contentView = bodyView.contentWrapperView

        switch style?.verticalAlignment {
        case "top":
            contentView.topAnchor.constraint(
                equalTo: bodyView.safeAreaLayoutGuide.topAnchor,
                constant: style?.marginTop ?? 0
            ).isActive = true
        case "bottom":
            let constraint = contentView.bottomAnchor.constraint(
                equalTo: bodyView.safeAreaLayoutGuide.bottomAnchor,
                constant: -1 * (style?.marginBottom ?? 0)
            )
            constraint.isActive = true
            bottomConstraint = constraint
        default:
            contentView.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor).isActive = true
        }

        switch style?.horizontalAlignment {
        case "leading":
            contentView.leadingAnchor.constraint(
                equalTo: bodyView.layoutMarginsGuide.leadingAnchor,
                constant: style?.marginLeading ?? 0
            ).isActive = true
        case "trailing":
            contentView.trailingAnchor.constraint(
                equalTo: bodyView.layoutMarginsGuide.trailingAnchor,
                constant: -1 * (style?.marginTrailing ?? 0)
            ).isActive = true
        default:
            contentView.centerXAnchor.constraint(equalTo: bodyView.centerXAnchor).isActive = true
        }

        if let width = style?.width, width > 0 {
            let widthConstraint = contentView.widthAnchor.constraint(equalToConstant: width)
            // lower priority here so that the constraint on width being <= the readableContentGuide width
            // set in the ExperienceWrapperView by default takes priority, if width is too large
            widthConstraint.priority = .init(999)
            widthConstraint.isActive = true
        } else {
            // if no explicit width set, defaults to the readable content guide width
            contentView.widthAnchor.constraint(equalTo: bodyView.readableContentGuide.widthAnchor).isActive = true
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        // if this container has opted out of updating size, for example background content containers, do not update
        // this view controller's preferredContentSize or height constraint
        if let dynamicSizing = container as? DynamicContentSizing, !dynamicSizing.updatesPreferredContentSize {
            return
        }

        // If the current child controller changes it's preferred size, propagate that for use in the bodyView
        bodyView.preferredContentSize = container.preferredContentSize
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

    @objc
    private func slideoutPanned(recognizer: UIPanGestureRecognizer) {
        guard let panView = recognizer.view else { return }

        let canDragToDismiss = !experienceContainerViewController.isModalInPresentation
        let allowedEdges = canDragToDismiss ? self.allowedEdges : []

        let touchPoint = recognizer.location(in: view)

        switch recognizer.state {
        case .began:
            initialCenter = panView.center
            initialOffset = CGPoint(
                x: touchPoint.x - panView.center.x,
                y: touchPoint.y - panView.center.y
            )
        case .changed:
            let dragCenter = CGPoint(
                x: touchPoint.x - initialOffset.x,
                y: touchPoint.y - initialOffset.y
            )

            panView.center = DragDirection(initial: initialCenter, new: dragCenter)
                .newPoint(allowedEdges: allowedEdges)
        case .ended, .cancelled:
            let gestureVelocity = recognizer.velocity(in: view)
            let adjustedVelocity = DragDirection(initial: .zero, new: gestureVelocity)
                .newPoint(allowedEdges: allowedEdges)

            let projectedCenter = CGPoint(
                x: panView.center.x + project(initialVelocity: adjustedVelocity.x),
                y: panView.center.y + project(initialVelocity: adjustedVelocity.y)
            )

            let isSufficientToDismiss = DragDirection(initial: initialCenter, new: projectedCenter)
                .isSufficientToDismiss(allowedEdges: allowedEdges, size: panView.bounds, bounds: bodyView.bounds)

            let finalCenter = isSufficientToDismiss ? projectedCenter : initialCenter
            let relativeInitialVelocity = CGVector(
                dx: relativeVelocity(forVelocity: adjustedVelocity.x, from: panView.center.x, to: finalCenter.x),
                dy: relativeVelocity(forVelocity: adjustedVelocity.y, from: panView.center.y, to: finalCenter.y)
            )
            let timingParameters = UISpringTimingParameters(damping: 1, response: 0.4, initialVelocity: relativeInitialVelocity)
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
            animator.addAnimations {
                panView.center = finalCenter

                if isSufficientToDismiss {
                    self.bodyView.backdropView.alpha = 0
                }
            }
            if isSufficientToDismiss {
                animator.addCompletion { _ in
                    self.dismiss(animated: false)
                }
            }
            animator.startAnimation()
        default: break
        }
    }

    /// Distance traveled after decelerating to zero velocity at a constant rate.
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat = UIScrollView.DecelerationRate.normal.rawValue) -> CGFloat {
        return (initialVelocity / 1_000) * decelerationRate / (1 - decelerationRate)
    }

    /// Calculates the relative velocity needed for the initial velocity of the animation.
    private func relativeVelocity(forVelocity velocity: CGFloat, from currentValue: CGFloat, to targetValue: CGFloat) -> CGFloat {
        guard currentValue - targetValue != 0 else { return 0 }
        return velocity / (targetValue - currentValue)
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        slideAnimationController?.transitionType = .dismissal
        return slideAnimationController
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        slideAnimationController?.transitionType = .presentation
        return slideAnimationController
    }
}
