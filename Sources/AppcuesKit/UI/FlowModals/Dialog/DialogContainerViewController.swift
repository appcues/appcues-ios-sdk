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

    init(wrapping dialogViewController: UIViewController) {
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
    }

    func configureSkippable(isSkippable: Bool) -> Self {
        if isSkippable {
            containerView.backgroundView.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))
        }

        return self
    }

    func configureStyle(_ style: ExperienceComponent.Style?, backdropColor: UIColor?) -> Self {
        containerView.backgroundView.backgroundColor = backdropColor
        containerView.dialogView.backgroundColor = UIColor(dynamicColor: style?.backgroundColor)
        containerView.dialogView.layer.cornerRadius = style?.cornerRadius ?? 0

        containerView.dialogView.layer.borderColor = UIColor(dynamicColor: style?.borderColor)?.cgColor
        containerView.dialogView.layer.borderWidth = CGFloat(style?.borderWidth) ?? 0

        containerView.shadowLayer = CAShapeLayer(shadowModel: style?.shadow)

        return self
    }

    @objc
    private func didTapBackground() {
        dismiss(animated: true)
    }
}
