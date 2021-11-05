//
//  ExperienceStepHostingController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal class ExperienceStepHostingController<Content: View>: UIHostingController<ExperienceStepRootView<Content>>, AppcuesController {

    init(rootView: Content, viewModel: ExperienceStepViewModel) {
        super.init(rootView: ExperienceStepRootView(rootView: rootView, viewModel: viewModel))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
