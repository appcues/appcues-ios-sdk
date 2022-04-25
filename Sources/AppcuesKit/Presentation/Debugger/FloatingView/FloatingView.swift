//
//  FloatingView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class FloatingView: UIView {

    private let tapRecognizer = UITapGestureRecognizer()

    var onViewActivated: (() -> Void)?

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(asset: Asset.Image.debugIcon))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .secondarySystemBackground
        imageView.clipsToBounds = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "Appcues Debug Panel"

        addSubview(imageView)
        imageView.pin(to: self)

        addGestureRecognizer(tapRecognizer)
        tapRecognizer.addTarget(self, action: #selector(viewTapped))

        layer.shadowColor = UIColor(hex: "#3923B7")?.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowOffset = .zero
        layer.shadowRadius = 12

        setupParallax()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Round the self corners for a nice automatic accessibility path,
        // but don't clip since that would obscure the unread indicator.
        layer.cornerRadius = frame.width / 2
        // Clipping the imageView is ok though.
        imageView.layer.cornerRadius = frame.width / 2
    }

    @objc
    private func viewTapped(recognizer: UITapGestureRecognizer) {
        onViewActivated?()
    }

    func animatePosition(to point: CGPoint, animated: Bool = true, haptics: Bool = true) {
        let animations: () -> Void = {
            self.center = point
        }

        if haptics {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        if animated {
            UIView.animate(
                withDuration: 0.7,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0,
                animations: animations,
                completion: nil
            )
        } else {
            animations()
        }
    }

    func animateSnap(to point: CGPoint, animated: Bool = true, haptics: Bool = true) {
        let animations: () -> Void = {
            self.center = point
        }

        if haptics {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }

        if animated {
            let timing = UISpringTimingParameters(
                damping: 0.6,
                response: 0.25,
                initialVelocity: CGVector.zero
            )
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)
            animator.addAnimations(animations)
            animator.startAnimation()
        } else {
            animations()
        }
    }

    func animateVisibility(visible isVisible: Bool, animated: Bool, haptics: Bool, completion: (() -> Void)? = nil) {
        let animations: () -> Void = {
            self.alpha = isVisible ? 1 : 0
            self.transform = isVisible ? CGAffineTransform(scaleX: 1, y: 1) : CGAffineTransform(scaleX: 0.001, y: 0.001)
        }

        let completion: (Bool) -> Void = { _ in
            completion?()
        }

        if animated {
            UIView.animate(
                withDuration: 0.4,
                animations: animations,
                completion: completion
            )
        } else {
            animations()
            completion(true)
        }
    }

    private func setupParallax() {
        let amount = 20

        let horizontalShift = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontalShift.minimumRelativeValue = -amount
        horizontalShift.maximumRelativeValue = amount

        let verticalShift = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        verticalShift.minimumRelativeValue = -amount
        verticalShift.maximumRelativeValue = amount

        let horizontalShadow = UIInterpolatingMotionEffect(keyPath: "layer.shadowOffset.width", type: .tiltAlongHorizontalAxis)
        horizontalShadow.minimumRelativeValue = amount
        horizontalShadow.maximumRelativeValue = -amount

        let verticalShadow = UIInterpolatingMotionEffect(keyPath: "layer.shadowOffset.height", type: .tiltAlongVerticalAxis)
        verticalShadow.minimumRelativeValue = amount
        verticalShadow.maximumRelativeValue = -amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontalShift, verticalShift, horizontalShadow, verticalShadow]
        self.addMotionEffect(group)
    }

    // MARK: Accessibility

    override func accessibilityActivate() -> Bool {
        onViewActivated?()
        return onViewActivated != nil
    }
}
