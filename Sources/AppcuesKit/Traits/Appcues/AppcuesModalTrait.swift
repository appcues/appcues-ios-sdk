//
//  AppcuesModalTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesModalTrait: ExperienceTrait {
    static let type = "@appcues/modal"

    var presentationStyle: PresentationStyle
    var cornerRadius: CGFloat?
    var skippable: Bool

    init?(config: [String: Any]?) {
        if let presentationStyle = PresentationStyle(rawValue: config?["presentationStyle"] as? String ?? "") {
            self.presentationStyle = presentationStyle
        } else {
            return nil
        }

        if let cornerRadius = config?["cornerRadius"] as? Int {
            self.cornerRadius = CGFloat(cornerRadius)
        }

        self.skippable = config?["skippable"] as? Bool ?? false
    }

    func apply(to experienceController: UIViewController, containedIn wrappingController: UIViewController) -> UIViewController {
        wrappingController.modalPresentationStyle = presentationStyle.modalPresentationStyle

        if skippable {
            experienceController.addDismissButton()
        }

        if presentationStyle == .dialog {
            return DialogContainerViewController(
                dialogViewController: experienceController,
                skippable: skippable,
                cornerRadius: cornerRadius)
        }

        wrappingController.isModalInPresentation = !skippable

        if #available(iOS 15.0, *), let sheet = wrappingController.sheetPresentationController {
            sheet.preferredCornerRadius = cornerRadius

            if presentationStyle == .halfSheet {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }

        return wrappingController
    }
}

extension AppcuesModalTrait {
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
        let dismissButton = UIButton(type: .close)
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
