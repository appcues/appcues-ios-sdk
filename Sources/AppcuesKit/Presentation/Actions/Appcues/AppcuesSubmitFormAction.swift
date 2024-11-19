//
//  AppcuesSubmitFormAction.swift
//  AppcuesKit
//
//  Created by Matt on 2022-09-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal class AppcuesSubmitFormAction: AppcuesExperienceAction, ExperienceActionQueueTransforming {
    struct Config: Decodable {
        let skipValidation: Bool
    }

    static let type = "@appcues/submit-form"

    private weak var appcues: Appcues?
    private let renderContext: RenderContext

    let skipValidation: Bool

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues
        renderContext = configuration.renderContext

        let config = configuration.decode(Config.self)
        self.skipValidation = config?.skipValidation ?? false
    }

    func execute(completion: ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        defer {
            completion()
        }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        let analyticsPublisher = appcues.container.resolve(AnalyticsPublishing.self)

        guard let experienceData = experienceRenderer.experienceData(forContext: renderContext),
              let stepIndex = experienceRenderer.stepIndex(forContext: renderContext),
              let stepState = experienceData.state(for: stepIndex) else { return }

        let interactionProperties = Dictionary(propertiesFrom: experienceData, stepIndex: stepIndex)
            .merging([
                "interactionType": "Form Submitted",
                // Passing the actual StepState model is safe because of specific handling in `encodeSkippingInvalid`.
                "interactionData": [ "formResponse": stepState ]
            ])

        analyticsPublisher.conditionallyPublish(TrackingUpdate(
            type: .profile(interactive: false),
            properties: stepState.formattedAsProfileUpdate(),
            isInternal: true
        ), shouldPublish: experienceData.published)

        analyticsPublisher.conditionallyPublish(TrackingUpdate(
            type: .event(name: Events.Experience.stepInteraction.rawValue, interactive: false),
            properties: interactionProperties,
            isInternal: true
        ), shouldPublish: experienceData.published)
    }

    // If the form state is invalid, remove this action and all subsequent.
    func transformQueue(_ queue: [AppcuesExperienceAction], index: Int, inContext appcues: Appcues) -> [AppcuesExperienceAction] {
        guard !skipValidation else { return queue }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)

        guard let experienceData = experienceRenderer.experienceData(forContext: renderContext),
              let stepIndex = experienceRenderer.stepIndex(forContext: renderContext),
              let stepState = experienceData.state(for: stepIndex) else { return queue }

        if stepState.stepFormIsComplete {
            return queue
        } else {
            // Update the UI to show error states
            stepState.shouldShowErrors = true

            var truncatedQueue = queue
            // Remove this action and all subsequent
            truncatedQueue.removeSubrange(index..<truncatedQueue.count)
            return truncatedQueue
        }
    }
}
