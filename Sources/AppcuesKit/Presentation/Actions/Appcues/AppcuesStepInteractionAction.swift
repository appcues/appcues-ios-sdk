//
//  AppcuesStepInteractionAction.swift
//  AppcuesKit
//
//  Created by Matt on 2022-10-05.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// Internal-only action: This action isn't registered in the `ActionRegistry`.
@available(iOS 13.0, *)
internal class AppcuesStepInteractionAction: AppcuesExperienceAction {

    static let type = "@appcues/step_interaction"

    private weak var appcues: Appcues?
    private let renderContext: RenderContext

    let interactionType: String
    let viewDescription: String
    let category: String
    let destination: String

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        // An internal-only action, so can't be initialized from an Experience.Action model.
        return nil
    }

    init(appcues: Appcues?, renderContext: RenderContext, interactionType: String, viewDescription: String, category: String, destination: String) {
        self.appcues = appcues
        self.renderContext = renderContext
        self.interactionType = interactionType
        self.viewDescription = viewDescription
        self.category = category
        self.destination = destination
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        let analyticsPublisher = appcues.container.resolve(AnalyticsPublishing.self)
        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)

        var interactionProperties: [String: Any] = [
            "interactionType": interactionType,
            "interactionData": [
                "category": category,
                "destination": destination,
                "text": viewDescription
            ]
        ]

        if let experienceData = experienceRenderer.experienceData(forContext: renderContext),
           let stepIndex = experienceRenderer.stepIndex(forContext: renderContext) {
            interactionProperties = Dictionary(propertiesFrom: experienceData, stepIndex: stepIndex).merging(interactionProperties)
        }

        analyticsPublisher.publish(TrackingUpdate(
            type: .event(name: Events.Experience.stepInteraction.rawValue, interactive: false),
            properties: interactionProperties,
            isInternal: true
        ))

        completion()
    }
}
