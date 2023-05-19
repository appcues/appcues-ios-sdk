//
//  CustomEmbedRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2023-05-19.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

public protocol AppcuesEmbedView: UIView {
    init(configuration: AppcuesExperiencePluginConfiguration)
}

@available(iOS 13.0, *)
internal class CustomEmbedRegistry {
    private var registeredEmbeds: [String: AppcuesEmbedView.Type] = [:]
    private weak var appcues: Appcues?

    init(container: DIContainer) {
        self.appcues = container.owner
    }

    func register(embed identifier: String, type: AppcuesEmbedView.Type) {
        guard registeredEmbeds[identifier] == nil else {
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCTestBundlePath"] == nil {
                assertionFailure("Embed with identifier \(identifier) is already registered.")
            }
            #endif
            return
        }

        registeredEmbeds[identifier] = type
    }

    func embed(
        for model: ExperienceComponent.CustomEmbedModel,
        renderContext: RenderContext
    ) -> (AppcuesEmbedView.Type, AppcuesExperiencePluginConfiguration)? {
        guard let type = registeredEmbeds[model.identifier] else { return nil }

        return(
            type,
            AppcuesExperiencePluginConfiguration(
                model.configDecoder,
                level: .step,
                renderContext: renderContext,
                appcues: appcues
            )
        )
    }
}
