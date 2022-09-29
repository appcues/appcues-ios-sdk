//
//  AppcuesSubmitFormAction.swift
//  AppcuesKit
//
//  Created by Matt on 2022-09-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesSubmitFormAction: ExperienceAction, ExperienceActionQueueTransforming {
    static let type = "@appcues/submit-form"

    let skipValidation: Bool

    required init?(config: [String: Any]?) {
        self.skipValidation = config?["skipValidation"] as? Bool ?? false
    }

    func execute(inContext appcues: Appcues, completion: ActionRegistry.Completion) {
        defer {
            completion()
        }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        let analyticsPublisher = appcues.container.resolve(AnalyticsPublishing.self)

        guard let experienceData = experienceRenderer.getCurrentExperienceData(),
              let stepIndex = experienceRenderer.getCurrentStepIndex(),
              let stepState = experienceData.state(for: stepIndex) else { return }

        let interactionProperties = [
            "interactionType": "Form Submitted",
            // Passing the actual StepState model is safe because of specific handling in `encodeSkippingInvalid`.
            "interactionData": [ "formResponse": stepState ]
        ]
            .merging(LifecycleEvent.properties(experienceData, stepIndex)) { first, _ in first }

        analyticsPublisher.publish(TrackingUpdate(
            type: .profile,
            properties: stepState.formattedAsProfileUpdate(),
            isInternal: true))

        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: LifecycleEvent.stepInteraction.rawValue, interactive: false),
            properties: interactionProperties,
            isInternal: true))
    }

    // If the form state is invalid, remove this action and all subsequent.
    func transformQueue(_ queue: [ExperienceAction], index: Int, inContext appcues: Appcues) -> [ExperienceAction] {
        guard !skipValidation else { return queue }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)

        guard let experienceData = experienceRenderer.getCurrentExperienceData(),
              let stepIndex = experienceRenderer.getCurrentStepIndex(),
              let stepState = experienceData.state(for: stepIndex) else { return queue }

        if stepState.stepFormIsComplete {
            return queue
        } else {
            var truncatedQueue = queue
            // Remove this action and all subsequent
            truncatedQueue.removeSubrange(index..<truncatedQueue.count)
            return truncatedQueue
        }
    }
}
