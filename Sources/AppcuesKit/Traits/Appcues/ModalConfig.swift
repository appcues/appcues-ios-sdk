//
//  ModalConfig.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-13.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// Shared modal configuration for traits.
internal struct ModalConfig {

    var presentationStyle: PresentationStyle
    var backdropColor: UIColor?
    var modalStyle: ExperienceComponent.Style?
    var skippable: Bool

    init?(config: [String: Any]?) {
        if let presentationStyle = PresentationStyle(rawValue: config?["presentationStyle"] as? String ?? "") {
            self.presentationStyle = presentationStyle
        } else {
            return nil
        }

        self.backdropColor = UIColor(dynamicColor: config?["backdropColor", decodedAs: ExperienceComponent.Style.DynamicColor.self])
        self.modalStyle = config?["style", decodedAs: ExperienceComponent.Style.self]
        self.skippable = config?["skippable"] as? Bool ?? false
    }

    func apply(to experienceController: UIViewController, containedIn wrappingController: UIViewController) -> UIViewController {
        wrappingController.modalPresentationStyle = presentationStyle.modalPresentationStyle

        if skippable {
            experienceController.addDismissButton()
        }

        if presentationStyle == .dialog {
            return DialogContainerViewController(wrapping: experienceController)
                .configureSkippable(isSkippable: skippable)
                .configureStyle(modalStyle, backdropColor: backdropColor)
        }

        if let backgroundColor = UIColor(dynamicColor: modalStyle?.backgroundColor) {
            experienceController.view.backgroundColor = backgroundColor
        }

        wrappingController.isModalInPresentation = !skippable

        if #available(iOS 15.0, *), let sheet = wrappingController.sheetPresentationController {
            sheet.preferredCornerRadius = CGFloat(modalStyle?.cornerRadius)

            if presentationStyle == .halfSheet {
                sheet.detents = [.medium()]
            }
        }

        return wrappingController
    }
}

extension ModalConfig {
    enum PresentationStyle: String {
        case full
        case dialog
        case sheet
        case halfSheet

        var modalPresentationStyle: UIModalPresentationStyle {
            switch self {
            case .full, .dialog:
                return .overFullScreen
            case .sheet:
                return .formSheet
            case .halfSheet:
                return .pageSheet
            }
        }
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
