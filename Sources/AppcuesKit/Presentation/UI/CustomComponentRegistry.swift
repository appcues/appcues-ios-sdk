//
//  CustomComponentRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2023-05-19.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal struct CustomComponentData {
    let type: AppcuesCustomComponentViewController.Type
    let config: AppcuesExperiencePluginConfiguration
    let actionController: AppcuesExperienceActions
}

@available(iOS 13.0, *)
internal class CustomComponentRegistry {
    private var registeredComponents: [String: AppcuesCustomComponentViewController.Type] = [:]

    init() {}

    func registerCustomComponent(identifier: String, type: AppcuesCustomComponentViewController.Type) {
        registeredComponents[identifier] = type
    }

    func customComponent(
        for model: ExperienceComponent.CustomComponentModel,
        renderContext: RenderContext,
        appcuesInstance: Appcues?
    ) -> CustomComponentData? {
        guard let type = registeredComponents[model.identifier] else { return nil }

        return CustomComponentData(
            type: type,
            config: AppcuesExperiencePluginConfiguration(
                model.configDecoder,
                level: .step,
                renderContext: renderContext,
                appcues: appcuesInstance
            ),
            actionController: AppcuesExperienceActions(
                appcues: appcuesInstance,
                renderContext: renderContext,
                identifier: model.identifier
            )
        )
    }
}
