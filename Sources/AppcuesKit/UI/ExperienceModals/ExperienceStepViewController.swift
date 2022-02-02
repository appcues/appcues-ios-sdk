//
//  ExperienceStepViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class ExperienceStepViewController: UIViewController {

    let viewModel: ExperienceStepViewModel

    lazy var stepView = ExperienceStepView()

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

        embedChildViewController(contentViewController, inSuperview: stepView.scrollView)
        NSLayoutConstraint.activate([
            contentViewController.view.widthAnchor.constraint(equalTo: stepView.scrollView.widthAnchor)
        ])
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        preferredContentSize = contentViewController.view.frame.size
    }

}

extension ExperienceStepViewController {
    class ExperienceStepView: UIView {
        lazy var scrollView: UIScrollView = {
            let view = UIScrollView()
            // Force a consistent safe area behavior regardless of whether the content scrolls
            view.contentInsetAdjustmentBehavior = .always
            return view
        }()

        init() {
            super.init(frame: .zero)

            addSubview(scrollView)
            scrollView.pin(to: self)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
