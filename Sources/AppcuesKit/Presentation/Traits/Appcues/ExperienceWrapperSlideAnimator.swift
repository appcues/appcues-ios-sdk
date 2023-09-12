//
//  ExperienceWrapperSlideAnimator.swift
//  AppcuesKit
//
//  Created by James Ellis on 9/7/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperienceWrapperSlideAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    enum ModalTransitionType {
        case presentation
        case dismissal
    }

    var transitionType: ModalTransitionType = .presentation

    private let view: ExperienceWrapperView
    private let edge: AppcuesModalTrait.TransitionEdge

    var backdropView: UIView?

    private var transitionDuration: TimeInterval {
        switch transitionType {
        case .presentation:
            return 1.0
        case .dismissal:
            return 0.4
        }
    }

    init(view: ExperienceWrapperView, edge: AppcuesModalTrait.TransitionEdge) {
        self.view = view
        self.edge = edge
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let animator: UIViewPropertyAnimator
        switch transitionType {
        case .presentation:
            animator = UIViewPropertyAnimator(duration: transitionDuration, dampingRatio: 0.82)
        case .dismissal:
            animator = UIViewPropertyAnimator(duration: transitionDuration, curve: UIView.AnimationCurve.easeIn)
        }

        switch transitionType {
        case .presentation:
            // We need to add the modal to the view hierarchy,
            // and perform the animation.
            if let toView = transitionContext.view(forKey: .to) {
                toView.translatesAutoresizingMaskIntoConstraints = false
                transitionContext.containerView.addSubview(toView)
                toView.pin(to: transitionContext.containerView)
                toView.layoutIfNeeded()
            }

            // move the modal off screen
            UIView.performWithoutAnimation { beginTransition(transitionContext) }
            // then slide it in
            animator.addAnimations { [weak self] in self?.endTransition() }
        case .dismissal:
            // The modal is already in the view hierarchy,
            // so we just perform the animation.
            animator.addAnimations { [weak self] in self?.beginTransition(transitionContext) }
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(true)
        }

        animator.startAnimation()
    }

    private func beginTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        var offsetX: CGFloat
        var offsetY: CGFloat

        backdropView?.alpha = 0.0

        switch edge {
        case .top:
            offsetX = 0
            offsetY = -1 * view.shadowWrappingView.frame.maxY
        case .leading:
            offsetX = -1 * view.shadowWrappingView.frame.maxX
            offsetY = 0
        case .bottom:
            offsetX = 0
            offsetY = transitionContext.containerView.bounds.height - view.shadowWrappingView.frame.minY
        case .trailing:
            offsetX = transitionContext.containerView.bounds.width - view.shadowWrappingView.frame.minX
            offsetY = 0
        case .center:
            // center+center special case - will be similar to bottom, but not start fully offscreen
            offsetX = 0
            offsetY = view.shadowWrappingView.frame.height / 2.0
            view.contentWrapperView.alpha = 0.0
        }

        view.contentWrapperView.transform = CGAffineTransform.identity.translatedBy(x: offsetX, y: offsetY)
    }

    private func endTransition() {
        view.contentWrapperView.transform = CGAffineTransform.identity
        view.contentWrapperView.alpha = 1.0
        backdropView?.alpha = 1.0
    }
}
