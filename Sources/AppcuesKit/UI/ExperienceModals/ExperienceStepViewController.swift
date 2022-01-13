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

    override func viewDidLoad() {
        super.viewDidLoad()

        embedChildViewController(contentViewController, inSuperview: view)
    }
}
