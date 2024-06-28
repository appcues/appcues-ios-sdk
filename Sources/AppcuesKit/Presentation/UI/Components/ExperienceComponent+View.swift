//
//  ExperienceComponent+View.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct CustomFrameRepresentable: UIViewControllerRepresentable {
    private let type: AppcuesCustomFrameViewController.Type
    private let configuration: AppcuesExperiencePluginConfiguration

    init?(on viewModel: ExperienceStepViewModel, for model: ExperienceComponent.CustomFrameModel) {
        guard let (type, configuration) = viewModel.embed(for: model) else { return nil }
        self.type = type
        self.configuration = configuration
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = type.init(configuration: configuration)
        return viewController ?? UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
}

@available(iOS 13.0, *)
internal struct CustomFrame: View {
    let model: ExperienceComponent.CustomFrameModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        CustomFrameRepresentable(on: viewModel, for: model)
            .setupActions(on: viewModel, for: model)
            .applyAllAppcues(style)
    }
}

@available(iOS 13.0, *)
extension ExperienceComponent {

    @ViewBuilder var view: some View {
        // Using `AnyView` here drastically improves memory and CPU usage
        switch self {
        case .stack(let model):
            AnyView(AppcuesStack(model: model))
        case .box(let model):
            AnyView(AppcuesBox(model: model))
        case .text(let model):
            AnyView(AppcuesText(model: model))
        case .button(let model):
            AnyView(AppcuesButton(model: model))
        case .image(let model):
            AnyView(AppcuesImage(model: model))
        case .embed(let model):
            AnyView(AppcuesEmbed(model: model))
        case .textInput(let model):
            AnyView(AppcuesTextInput(model: model))
        case .optionSelect(let model):
            AnyView(AppcuesOptionSelect(model: model))
        case .customFrame(let model):
            AnyView(CustomFrame(model: model))
        case .spacer(let model):
            AnyView(Spacer(minLength: CGFloat(model.spacing)))
        }
    }
}

extension ExperienceComponent.IntrinsicSize {
    var aspectRatio: CGFloat {
        width / height
    }
}
