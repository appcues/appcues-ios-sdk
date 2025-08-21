//
//  AppcuesConditionalAction.swift
//  Appcues
//
//  Created by Matt on 2025-08-12.
//  Copyright © 2025 Appcues. All rights reserved.
//

import Foundation

internal struct ConditionalState {
    let formState: [UUID: Any]

    subscript (blockID key: UUID) -> String? {
        return formState[key] as? String
    }
}

@available(iOS 13.0, *)
internal class AppcuesConditionalAction: AppcuesExperienceAction, ExperienceActionQueueTransforming {
    struct Check: Decodable {
        let condition: Clause?
        let actions: [Experience.Action]
    }

    struct Config: Decodable {
        let checks: [Check]
    }

    static let type = "@appcues/conditional"

    private let level: AppcuesExperiencePluginConfiguration.Level
    private let renderContext: RenderContext

    let checks: [Check]

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }

        self.level = configuration.level
        self.renderContext = configuration.renderContext
        self.checks = config.checks
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        completion()
    }

    func transformQueue(_ queue: [AppcuesExperienceAction], index: Int, inContext appcues: Appcues) -> [AppcuesExperienceAction] {
        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        let actionRegistry = appcues.container.resolve(ActionRegistry.self)

        guard let formState = experienceRenderer.experienceData(forContext: renderContext)?.flatFormState() else { return queue }

        let state = ConditionalState(formState: formState)

        guard let matchingCheck = checks.first(where: { $0.condition?.evaluate(state: state) != false }) else {
            appcues.config.logger.info("@appcues/conditional no checks satisfied")
            return queue
        }
        
        var updatedQueue = queue
        let actionInstances = actionRegistry.makeInstances(
            actionModels: matchingCheck.actions,
            level: self.level,
            renderContext: self.renderContext
        )

        updatedQueue.replaceSubrange(index...index, with: actionInstances)
        appcues.config.logger.info(
            "@appcues/conditional satisfied %{public}@, adding %{public}@ action(s) to queue",
            matchingCheck.condition?.description ?? "else",
            "\(actionInstances.count)"
        )
        return updatedQueue
    }
}
