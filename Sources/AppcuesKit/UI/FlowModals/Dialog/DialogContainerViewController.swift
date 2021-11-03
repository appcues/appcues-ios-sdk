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

    init(dialogViewController: UIViewController) {
        self.dialogViewController = dialogViewController
        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = containerView
        embedChildViewController(dialogViewController, inSuperview: containerView.dialogView)
        containerView.backgroundView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))
    }

    @objc
    private func didTapBackground() {
        // TODO: this should be controller by the @appcues/skippable trait.
        // In general traits should be standalone and shouldn't need to know implementation details, or about other traits,
        // but skippable might be a special case. Alternatively, if @appcues/modal had a property that determined if
        // background tap and swipe to dismiss were allowed, that would do it, and skippable would solely be for the button.
        dismiss(animated: true)
    }
}
