//
//  ExperimentalVibrancyTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperimentalVibrancyTrait: WrapperCreatingTrait {
    static let type = "@experimental/vibrancy"

    let style: UIBlurEffect.Style

    required init?(config: [String: Any]?) {
        self.style = UIBlurEffect.Style(string: config?["style"] as? String)
    }

    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController {
        VibrancyContainerViewController(wrapping: containerController, style: style)
    }

    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController) {
        wrapperController.view.insertSubview(backdropView, at: 0)
        backdropView.pin(to: wrapperController.view)
    }
}

@available(iOS 13.0, *)
private extension ExperimentalVibrancyTrait {

    class VibrancyContainerView: UIView {

        private let blurEffectView: UIVisualEffectView
        private let vibrancyEffectView: UIVisualEffectView

        var contentView: UIView { vibrancyEffectView.contentView }

        init(style: UIBlurEffect.Style) {
            let blurEffect = UIBlurEffect(style: style)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            vibrancyEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))

            super.init(frame: .zero)

            blurEffectView.contentView.addSubview(vibrancyEffectView)
            vibrancyEffectView.pin(to: blurEffectView)

            addSubview(blurEffectView)
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            blurEffectView.layer.cornerRadius = 20
            blurEffectView.layer.masksToBounds = true

            NSLayoutConstraint.activate([
                // ensure the dialog can't exceed the container height (it should scroll instead).
                blurEffectView.bottomAnchor.constraint(equalTo: readableContentGuide.bottomAnchor),
                // this is required so the dialogView has an initial non-zero height, after which it can start sizing to the content.
                blurEffectView.heightAnchor.constraint(greaterThanOrEqualToConstant: 1),
                blurEffectView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
                blurEffectView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class VibrancyContainerViewController: UIViewController {

        let style: UIBlurEffect.Style
        lazy var vibrancyView = VibrancyContainerView(style: style)

        private let viewController: UIViewController

        init(wrapping viewController: UIViewController, style: UIBlurEffect.Style) {
            self.viewController = viewController
            self.style = style
            super.init(nibName: nil, bundle: nil)

            modalTransitionStyle = .crossDissolve
            modalPresentationStyle = .overFullScreen
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            view = vibrancyView
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            embedChildViewController(viewController, inSuperview: vibrancyView.contentView)
        }
    }
}
