//
//  AppcuesSkippableTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal struct AppcuesSkippableTrait: ControllerExperienceTrait {
    static let type = "@appcues/skippable"

    init?(config: [String: Any]?) {
        // no config expected
    }

    func apply(to viewController: UIViewController) {
        viewController.addDismissButton()
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
