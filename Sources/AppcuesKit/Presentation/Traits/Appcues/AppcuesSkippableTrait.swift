//
//  AppcuesSkippableTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesSkippableTrait: ContainerDecoratingTrait, BackdropDecoratingTrait {
    static var type: String = "@appcues/skippable"

    private weak var containerController: UIViewController?
    private weak var view: UIViewController.CloseButton?
    private var gestureRecognizer: UITapGestureRecognizer?

    required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
    }

    func decorate(containerController: ExperienceContainerViewController) throws {
        self.containerController = containerController
        self.view = containerController.addDismissButton()

        // Allow interactive dismissal
        containerController.isModalInPresentation = false
    }

    func undecorate(containerController: ExperienceContainerViewController) throws {
        view?.removeFromSuperview()
        containerController.isModalInPresentation = true
    }

    func decorate(backdropView: UIView) throws {
        let recognizer = gestureRecognizer ?? UITapGestureRecognizer(target: self, action: #selector(didTapBackground))

        backdropView.addGestureRecognizer(recognizer)
        gestureRecognizer = recognizer
    }

    func undecorate(backdropView: UIView) throws {
        if let gestureRecognizer = gestureRecognizer {
            backdropView.removeGestureRecognizer(gestureRecognizer)
        }
    }

    @objc
    private func didTapBackground() {
        containerController?.dismiss(animated: true)
    }
}

@available(iOS 13.0, *)
private extension UIViewController {
    @discardableResult
    func addDismissButton() -> CloseButton {
        let dismissButton = CloseButton()
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)

        view.addSubview(dismissButton)

        dismissButton.accessibilityLabel = "Close"

        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: dismissButton.trailingAnchor, multiplier: 1),
            dismissButton.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1)
        ])

        return dismissButton
    }

    @objc
    func dismissButtonTapped() {
        dismiss(animated: true)
    }
}

@available(iOS 13.0, *)
private extension UIViewController {
    class CloseButton: UIButton {
        private static let size: CGFloat = 30

        init() {
            super.init(frame: .zero)

            layer.cornerRadius = CloseButton.size / 2
            layer.masksToBounds = true

            let symbolConfiguration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: CloseButton.size / 2, weight: .bold))
            let xmark = UIImage(systemName: "xmark", withConfiguration: symbolConfiguration)
            let blurEffect = UIBlurEffect(style: .systemThinMaterial)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)

            let blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.isUserInteractionEnabled = false
            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            let imageView = UIImageView(image: xmark)

            vibrancyEffectView.contentView.addSubview(imageView)
            blurredEffectView.contentView.addSubview(vibrancyEffectView)
            addSubview(blurredEffectView)

            imageView.center(in: vibrancyEffectView.contentView)
            vibrancyEffectView.pin(to: blurredEffectView.contentView)
            blurredEffectView.pin(to: self)

            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: CloseButton.size),
                heightAnchor.constraint(equalToConstant: CloseButton.size)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
