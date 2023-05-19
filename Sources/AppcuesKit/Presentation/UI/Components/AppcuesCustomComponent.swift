//
//  AppcuesCustomComponent.swift
//  AppcuesKit
//
//  Created by Matt on 2024-10-22.
//  Copyright © 2024 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct CustomComponentRepresentable: UIViewControllerRepresentable {
    private let type: AppcuesCustomComponentViewController.Type
    private let configuration: AppcuesExperiencePluginConfiguration
    private let actionController: AppcuesExperienceActions

    init?(on viewModel: ExperienceStepViewModel, for model: ExperienceComponent.CustomComponentModel) {
        guard let customComponentData = viewModel.customComponent(for: model) else { return nil }
        self.type = customComponentData.type
        self.configuration = customComponentData.config
        self.actionController = customComponentData.actionController
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = type.init(configuration: configuration, actionController: actionController)
        return viewController ?? UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
}

@available(iOS 13.0, *)
internal struct AppcuesCustomComponent: View {
    let model: ExperienceComponent.CustomComponentModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        CustomComponentRepresentable(on: viewModel, for: model)
            .applyAllAppcues(style)
    }
}
