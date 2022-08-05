//
//  AppcuesBackgroundContentTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-04.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal class AppcuesBackgroundContentTrait: StepDecoratingTrait, ContainerDecoratingTrait {
    static let type = "@appcues/background-content"

    let level: ExperienceTraitLevel
    let content: ExperienceComponent

    required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
        self.level = level

        if let content = config?["content", decodedAs: ExperienceComponent.self] {
            self.content = content
        } else {
            return nil
        }
    }

    func decorate(stepController viewController: UIViewController) throws {
        guard level == .step else { return }

        // Need to cast for access to the viewModel.
        guard let viewController = viewController as? ExperienceStepViewController else { return }

        applyBackground(with: viewController.viewModel, parent: viewController)
    }

    func decorate(containerController: ExperienceContainerViewController) throws {
        guard level == .group || level == .experience else { return }

        let emptyViewModel = ExperienceStepViewModel()

        applyBackground(with: emptyViewModel, parent: containerController)
    }

    private func applyBackground(with viewModel: ExperienceStepViewModel, parent viewController: UIViewController) {
        // Must have the environmentObject to avoid a crash.
        let backgroundContentVC = AppcuesHostingController(rootView: content.view
            .edgesIgnoringSafeArea(.all)
            .environmentObject(viewModel))
        backgroundContentVC.view.backgroundColor = .clear

        // The background is strictly decoration.
        backgroundContentVC.view.isAccessibilityElement = false
        backgroundContentVC.view.isUserInteractionEnabled = false

        // Ensure the background view has the least possible influence on the layout.
        backgroundContentVC.view.setContentCompressionResistancePriority(.init(rawValue: 1), for: .vertical)
        backgroundContentVC.view.setContentHuggingPriority(.init(rawValue: 1), for: .vertical)
        backgroundContentVC.view.setContentCompressionResistancePriority(.init(rawValue: 1), for: .horizontal)
        backgroundContentVC.view.setContentHuggingPriority(.init(rawValue: 1), for: .horizontal)

        viewController.addChild(backgroundContentVC)
        viewController.view.insertSubview(backgroundContentVC.view, at: 0)
        backgroundContentVC.view.pin(to: viewController.view)
        backgroundContentVC.didMove(toParent: viewController)

        viewController.view.clipsToBounds = true
    }
}
