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
    struct Config: Decodable {
        let buttonAppearance: ButtonAppearance?
        let ignoreBackdropTap: Bool?
    }

    static var type: String = "@appcues/skippable"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let buttonAppearance: ButtonAppearance
    private let ignoreBackdropTap: Bool

    private weak var containerController: UIViewController?
    private weak var view: UIViewController.CloseButton?
    private var gestureRecognizer: UITapGestureRecognizer?

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        let config = configuration.decode(Config.self)
        self.buttonAppearance = config?.buttonAppearance ?? .default
        self.ignoreBackdropTap = config?.ignoreBackdropTap ?? false
    }

    func decorate(containerController: ExperienceContainerViewController) throws {
        self.containerController = containerController

        if buttonAppearance != .hidden {
            self.view = containerController.addDismissButton(appearance: buttonAppearance)
        }

        // Allow interactive dismissal
        containerController.isModalInPresentation = false
    }

    func undecorate(containerController: ExperienceContainerViewController) throws {
        view?.removeFromSuperview()
        containerController.isModalInPresentation = true
    }

    func decorate(backdropView: UIView) throws {
        if !ignoreBackdropTap {
            let recognizer = gestureRecognizer ?? UITapGestureRecognizer(target: self, action: #selector(didTapBackground))

            backdropView.addGestureRecognizer(recognizer)
            gestureRecognizer = recognizer
        }
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
extension AppcuesSkippableTrait {
    enum ButtonAppearance: String, Decodable {
        case hidden
        case minimal
        case `default`
    }
}

@available(iOS 13.0, *)
private extension UIViewController {
    @discardableResult
    func addDismissButton(appearance: AppcuesSkippableTrait.ButtonAppearance) -> CloseButton {
        let dismissButton = CloseButton(minimal: appearance == .minimal)
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

        init(minimal: Bool = false) {
            super.init(frame: .zero)

            layer.cornerRadius = CloseButton.size / 2
            layer.masksToBounds = true

            let symbolFont = UIFont.systemFont(ofSize: CloseButton.size / 2, weight: minimal ? .regular : .bold)
            let xmark = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(font: symbolFont))
            let imageView = UIImageView(image: xmark)

            if minimal {
                imageView.tintColor = UIColor(white: 0.7, alpha: 1)
                layer.compositingFilter = "differenceBlendMode"
                addSubview(imageView)
                imageView.center(in: self)
            } else {
                let blurEffect = UIBlurEffect(style: .systemThinMaterial)
                let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)

                let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
                vibrancyEffectView.contentView.addSubview(imageView)
                imageView.center(in: vibrancyEffectView.contentView)

                let blurredEffectView = UIVisualEffectView(effect: blurEffect)
                blurredEffectView.isUserInteractionEnabled = false
                blurredEffectView.contentView.addSubview(vibrancyEffectView)
                vibrancyEffectView.pin(to: blurredEffectView.contentView)

                addSubview(blurredEffectView)
                blurredEffectView.pin(to: self)
            }

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
