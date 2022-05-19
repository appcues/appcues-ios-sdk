//
//  ExperienceStepViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class ExperienceStepViewController: UIViewController {

    let viewModel: ExperienceStepViewModel

    lazy var stepView = ExperienceStepView()
    var padding: NSDirectionalEdgeInsets {
        get { stepView.contentView.directionalLayoutMargins }
        set { stepView.contentView.directionalLayoutMargins = newValue }
    }

    private let contentViewController: UIViewController

    init(viewModel: ExperienceStepViewModel) {
        self.viewModel = viewModel

        let rootView = ExperienceStepRootView(rootView: viewModel.step.content.view, viewModel: viewModel)
        self.contentViewController = AppcuesHostingController(rootView: rootView)
        self.contentViewController.view.backgroundColor = .clear

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = stepView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(contentViewController)
        stepView.contentView.addSubview(contentViewController.view)
        contentViewController.view.pin(to: stepView.contentView.layoutMarginsGuide)
        contentViewController.didMove(toParent: self)
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        let contentSize = stepView.scrollView.contentSize
        preferredContentSize = CGSize(
            width: contentSize.width + additionalSafeAreaInsets.left + additionalSafeAreaInsets.right,
            height: contentSize.height + additionalSafeAreaInsets.top + additionalSafeAreaInsets.bottom
        )
    }

}

@available(iOS 13.0, *)
extension ExperienceStepViewController {
    class ExperienceStepView: UIView {
        lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            view.translatesAutoresizingMaskIntoConstraints = false
            // Force a consistent safe area behavior regardless of whether the content scrolls
            view.contentInsetAdjustmentBehavior = .always
            return view
        }()

        lazy var contentView: UIView = {
            let view = UIView()
            view.directionalLayoutMargins = .zero
            return view
        }()

        init() {
            super.init(frame: .zero)

            addSubview(scrollView)
            scrollView.addSubview(contentView)
            contentView.pin(to: scrollView)
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: topAnchor),
                scrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

                contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
