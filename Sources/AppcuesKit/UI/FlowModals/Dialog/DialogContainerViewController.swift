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

    private let dialogViewController: ModalGroupViewController

    init(dialogViewController: ModalGroupViewController) {
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
        dialogViewController.closeModal()
    }
}
