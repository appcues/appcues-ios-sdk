//
//  AppcuesSkippableTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class AppcuesSkippableTrait: ContainerDecoratingTrait, BackdropDecoratingTrait {
    static var type: String = "@appcues/skippable"

    let groupID: String?

    private weak var containerController: UIViewController?

    required init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String
    }

    func decorate(containerController: ExperienceContainerViewController) {
        self.containerController = containerController
        containerController.addDismissButton()

        // Allow interactive dismissal
        containerController.isModalInPresentation = false
    }

    func decorate(backdropView: UIView) {
        backdropView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))
    }

    @objc
    private func didTapBackground() {
        containerController?.dismiss(animated: true)
    }
}

private extension UIViewController {
    func addDismissButton() {
        let dismissButton = CloseButton()
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(dismissButtonTapped), for: .touchUpInside)

        view.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: dismissButton.trailingAnchor, multiplier: 1),
            dismissButton.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1)
        ])
    }

    @objc
    func dismissButtonTapped() {
        dismiss(animated: true)
    }
}

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
