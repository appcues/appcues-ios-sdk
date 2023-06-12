//
//  AppcuesSkippableTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesSkippableTrait: AppcuesContainerDecoratingTrait, AppcuesBackdropDecoratingTrait {
    struct Config: Decodable {
        let buttonAppearance: ButtonAppearance?
        // swiftlint:disable:next discouraged_optional_boolean
        let ignoreBackdropTap: Bool?
        let buttonStyle: ExperienceComponent.Style?
    }

    static var type: String = "@appcues/skippable"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private weak var appcues: Appcues?
    private let experienceID: InstanceID?

    private let buttonAppearance: ButtonAppearance
    private let ignoreBackdropTap: Bool
    private let buttonStyle: ExperienceComponent.Style?

    private weak var containerController: UIViewController?
    private weak var view: UIViewController.CloseButton?
    private var gestureRecognizer: UITapGestureRecognizer?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues
        self.experienceID = configuration.experienceID

        let config = configuration.decode(Config.self)
        self.buttonAppearance = config?.buttonAppearance ?? .default
        self.ignoreBackdropTap = config?.ignoreBackdropTap ?? false
        self.buttonStyle = config?.buttonStyle
    }

    func decorate(containerController: AppcuesExperienceContainerViewController) throws {
        self.containerController = containerController

        if buttonAppearance != .hidden {
            let closeButton = containerController.addDismissButton(appearance: buttonAppearance, style: buttonStyle)
            closeButton.addTarget(self, action: #selector(dismissExperience), for: .touchUpInside)
            self.view = closeButton
        }

        // Allow interactive dismissal
        containerController.isModalInPresentation = false
    }

    func undecorate(containerController: AppcuesExperienceContainerViewController) throws {
        view?.removeFromSuperview()
        containerController.isModalInPresentation = true
    }

    func decorate(backdropView: UIView) throws {
        if !ignoreBackdropTap {
            let recognizer = gestureRecognizer ?? UITapGestureRecognizer(target: self, action: #selector(dismissExperience))

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
    private func dismissExperience() {
        guard let appcues = appcues else { return }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.dismiss(experienceID: experienceID, markComplete: false, completion: nil)
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
    func addDismissButton(appearance: AppcuesSkippableTrait.ButtonAppearance, style: ExperienceComponent.Style?) -> CloseButton {
        let dismissWrapView = UIView()
        dismissWrapView.translatesAutoresizingMaskIntoConstraints = false
        // 8px default margins for backwards compatibility
        dismissWrapView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: style?.marginTop ?? 8,
            leading: style?.marginLeading ?? 8,
            bottom: style?.marginBottom ?? 8,
            trailing: style?.marginTrailing ?? 8
        )

        let dismissButton = CloseButton(style: style, isMinimal: appearance == .minimal)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(dismissWrapView)
        dismissWrapView.addSubview(dismissButton)
        dismissButton.pin(to: dismissWrapView.layoutMarginsGuide)

        dismissButton.accessibilityLabel = "Close"

        NSLayoutConstraint.activate(dismissButtonConstraints(dismissWrapView, style: style))

        return dismissButton
    }

    private func dismissButtonConstraints(_ dismissButton: UIView, style: ExperienceComponent.Style?) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []

        // Default to top/trailing for backwards compatibility

        switch style?.verticalAlignment {
        case "center":
            constraints.append(dismissButton.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor))
        case "bottom":
            constraints.append(dismissButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor))
        default:
            // top
            constraints.append(dismissButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor))
        }

        switch style?.horizontalAlignment {
        case "leading":
            constraints.append(dismissButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor))
        case "center":
            constraints.append(dismissButton.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor))
        default:
            // trailing
            constraints.append(dismissButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor))
        }

        return constraints
    }
}

@available(iOS 13.0, *)
private extension UIViewController {
    class CloseButton: UIButton {
        private static let defaultSize: Double = 30

        init(style: ExperienceComponent.Style?, isMinimal: Bool = false) {
            super.init(frame: .zero)

            let width: Double = style?.width ?? style?.height ?? CloseButton.defaultSize
            let height: Double = style?.height ?? CloseButton.defaultSize

            layer.cornerRadius = style?.cornerRadius ?? min(width, height) / 2

            let symbolFont = UIFont.systemFont(ofSize: height / 2, weight: isMinimal ? .regular : .bold)
            let xmark = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(font: symbolFont))
            let imageView = UIImageView(image: xmark)

            let shadowView: UIView

            if isMinimal {
                shadowView = imageView

                if let foregroundColor = UIColor(dynamicColor: style?.foregroundColor) {
                    imageView.tintColor = foregroundColor
                } else {
                    imageView.tintColor = UIColor(white: 0.7, alpha: 1)
                    layer.compositingFilter = "differenceBlendMode"
                }

                addSubview(imageView)
                imageView.center(in: self)
            } else {
                shadowView = self

                if let foregroundColor = UIColor(dynamicColor: style?.foregroundColor) {
                    imageView.tintColor = foregroundColor
                    backgroundColor = UIColor(dynamicColor: style?.backgroundColor)

                    addSubview(imageView)
                    imageView.center(in: self)
                } else {
                    let blurredEffectView = wrapInSystemMaterials(view: imageView)
                    addSubview(blurredEffectView)
                    blurredEffectView.pin(to: self)
                }
            }

            NSLayoutConstraint.activate([
                widthAnchor.constraint(equalToConstant: width),
                heightAnchor.constraint(equalToConstant: height)
            ])

            if let borderColor = UIColor(dynamicColor: style?.borderColor), let borderWidth = style?.borderWidth {
                layer.borderColor = borderColor.cgColor
                layer.borderWidth = borderWidth
            }

            if let shadowModel = style?.shadow {
                shadowView.layer.shadowColor = UIColor(dynamicColor: shadowModel.color)?.cgColor
                shadowView.layer.shadowOpacity = 1
                shadowView.layer.shadowRadius = shadowModel.radius
                shadowView.layer.shadowOffset = CGSize(width: shadowModel.x, height: shadowModel.y)
                shadowView.layer.cornerRadius = layer.cornerRadius
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func wrapInSystemMaterials(view: UIView) -> UIView {
            let blurEffect = UIBlurEffect(style: .systemThinMaterial)
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)

            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyEffectView.contentView.addSubview(view)
            view.center(in: vibrancyEffectView.contentView)

            let blurredEffectView = UIVisualEffectView(effect: blurEffect)
            blurredEffectView.layer.cornerRadius = layer.cornerRadius
            blurredEffectView.layer.masksToBounds = true
            blurredEffectView.isUserInteractionEnabled = false
            blurredEffectView.contentView.addSubview(vibrancyEffectView)
            vibrancyEffectView.pin(to: blurredEffectView.contentView)

            return blurredEffectView
        }
    }
}
