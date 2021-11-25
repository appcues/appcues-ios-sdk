//
//  ExperienceStepHostingController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal class ExperienceStepHostingController<Content: View>: UIHostingController<ExperienceStepRootView<Content>> {

    weak var lifecycleHandler: ExperienceStepLifecycleHandler?

    init(rootView: Content, viewModel: ExperienceStepViewModel) {
        super.init(rootView: ExperienceStepRootView(rootView: rootView, viewModel: viewModel))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleHandler?.stepWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleHandler?.stepDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifecycleHandler?.stepWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifecycleHandler?.stepDidDisappear()
    }
}
