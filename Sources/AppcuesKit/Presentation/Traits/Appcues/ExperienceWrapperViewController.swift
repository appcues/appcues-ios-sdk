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

        bodyView.applyCornerRadius(CGFloat(style?.cornerRadius))
        bodyView.applyBorder(color: UIColor(dynamicColor: style?.borderColor), width: CGFloat(style?.borderWidth))

        if let shadowModel = style?.shadow {
            bodyView.shadowWrappingView.layer.shadowColor = UIColor(dynamicColor: shadowModel.color)?.cgColor
            bodyView.shadowWrappingView.layer.shadowOpacity = 1
            bodyView.shadowWrappingView.layer.shadowRadius = shadowModel.radius
            bodyView.shadowWrappingView.layer.shadowOffset = CGSize(width: shadowModel.x, height: shadowModel.y)
            bodyView.shadowWrappingView.layer.cornerRadius = style?.cornerRadius ?? 0
        }

        bodyView.setNeedsLayout()

        return self
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        // if this container has opted out of updating size, for example background content containers, do not update
        // this view controller's preferredContentSize or height constraint
        if let dynamicSizing = container as? DynamicContentSizing, !dynamicSizing.updatesPreferredContentSize {
            return
        }

        // If the current child controller changes it's preferred size, propagate that for use in the bodyVie
        bodyView.preferredContentSize = container.preferredContentSize
    }

}
