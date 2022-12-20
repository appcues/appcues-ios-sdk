//
//  ExperienceWrapperViewController.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/2/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperienceWrapperViewController<BodyView: ExperienceWrapperView>: UIViewController {

    lazy var bodyView = BodyView()

    private let experienceContainerViewController: UIViewController

    init(wrapping containerViewController: UIViewController) {
        self.experienceContainerViewController = containerViewController
        super.init(nibName: nil, bundle: nil)

        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = bodyView
        embedChildViewController(experienceContainerViewController, inSuperview: bodyView.contentWrapperView, respectLayoutMargins: true)
    }

    @discardableResult
    func configureStyle(_ style: ExperienceComponent.Style?) -> Self {
        bodyView.contentWrapperView.backgroundColor = UIColor(dynamicColor: style?.backgroundColor)
        bodyView.contentWrapperView.layer.cornerRadius = style?.cornerRadius ?? 0

        bodyView.contentWrapperView.layer.borderColor = UIColor(dynamicColor: style?.borderColor)?.cgColor
        if let borderWidth = CGFloat(style?.borderWidth) {
            bodyView.contentWrapperView.layer.borderWidth = borderWidth
            bodyView.contentWrapperView.layoutMargins = UIEdgeInsets(
                top: borderWidth,
                left: borderWidth,
                bottom: borderWidth,
                right: borderWidth)
        }

        bodyView.shadowLayer = CAShapeLayer(shadowModel: style?.shadow)

        switch style?.verticalAlignment {
        case "top":
            bodyView.contentWrapperView.topAnchor.constraint(equalTo: bodyView.safeAreaLayoutGuide.topAnchor).isActive = true
        case "bottom":
            bodyView.contentWrapperView.bottomAnchor.constraint(equalTo: bodyView.safeAreaLayoutGuide.bottomAnchor).isActive = true
        default:
            bodyView.contentWrapperView.centerYAnchor.constraint(equalTo: bodyView.centerYAnchor).isActive = true
        }

        return self
    }
}
