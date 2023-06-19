//
//  AppcuesBackgroundContentTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-04.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal class AppcuesBackgroundContentTrait: AppcuesStepDecoratingTrait, AppcuesContainerDecoratingTrait {
    struct Config: Decodable {
        let content: ExperienceComponent
    }

    static let type = "@appcues/background-content"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let renderContext: RenderContext

    private let level: AppcuesExperiencePluginConfiguration.Level
    private let content: ExperienceComponent

    private weak var backgroundViewController: UIViewController?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.renderContext = configuration.renderContext

        guard let config = configuration.decode(Config.self) else { return nil }

        self.level = configuration.level
        self.content = config.content
    }

    func decorate(stepController viewController: UIViewController) throws {
        guard level == .step else { return }

        // Need to cast for access to the viewModel.
        guard let viewController = viewController as? ExperienceStepViewController else { return }

        applyBackground(with: viewController.viewModel, parent: viewController)
    }

    func decorate(containerController: AppcuesExperienceContainerViewController) throws {
        guard level == .group || level == .experience else { return }

        let emptyViewModel = ExperienceStepViewModel(renderContext: renderContext)

        backgroundViewController = applyBackground(with: emptyViewModel, parent: containerController)
    }

    func undecorate(containerController: AppcuesExperienceContainerViewController) throws {
        if let backgroundViewController = backgroundViewController {
            containerController.unembedChildViewController(backgroundViewController)
        }
    }

    @discardableResult
    private func applyBackground(with viewModel: ExperienceStepViewModel, parent viewController: UIViewController) -> UIViewController {
        // Must have the environmentObject to avoid a crash.
        let backgroundContentVC = AppcuesHostingController(rootView: content.view
            .edgesIgnoringSafeArea(.all)
            .environmentObject(viewModel))
        backgroundContentVC.updatesPreferredContentSize = false
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

        return backgroundContentVC
    }
}
