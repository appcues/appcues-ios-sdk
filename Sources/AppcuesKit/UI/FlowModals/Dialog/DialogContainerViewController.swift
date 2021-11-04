//
//  DialogContainerViewController.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

internal class DialogContainerViewController: UIViewController {

    lazy var containerView = DialogContainerView()

    private let dialogViewController: UIViewController

    init(dialogViewController: UIViewController, skippable: Bool = false, cornerRadius: CGFloat? = nil) {
        self.dialogViewController = dialogViewController
        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen

        if let cornerRadius = cornerRadius {
            containerView.dialogView.layer.cornerRadius = cornerRadius
        }
        if skippable {
            containerView.backgroundView.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = containerView
        embedChildViewController(dialogViewController, inSuperview: containerView.dialogView)
    }

    @objc
    private func didTapBackground() {
        dismiss(animated: true)
    }
}
