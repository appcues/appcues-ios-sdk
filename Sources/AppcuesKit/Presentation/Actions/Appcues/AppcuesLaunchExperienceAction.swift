//
//  AppcuesLaunchExperienceAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesLaunchExperienceAction: ExperienceAction {
    static let type = "@appcues/launch-experience"

    let experienceID: String
    let trigger: ExperienceTrigger?

    required init?(config: DecodingExperienceConfig) {
        if let experienceID: String = config["experienceID"] {
            self.experienceID = experienceID
            self.trigger = nil
        } else {
            return nil
        }
    }

    init(experienceID: String, trigger: ExperienceTrigger) {
        self.experienceID = experienceID

        // This is used when a flow is triggered as a post flow action from another flow.
        // The trigger value is set during the StateMachine processing of the post-flow actions.
        self.trigger = trigger
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        let experienceLoading = appcues.container.resolve(ExperienceLoading.self)

        // If no trigger value is passedin, we know it was not triggered by a post-flow action
        // and we can use the standard `.launchExperienceAction` case, for a normal link within a flow
        // that launches another flow from a button, for example.
        let trigger = self.trigger ?? launchExperienceTrigger(appcues)

        experienceLoading.load(experienceID: experienceID, published: true, trigger: trigger) { _  in
            completion()
        }
    }

    private func launchExperienceTrigger(_ appcues: Appcues) -> ExperienceTrigger {
        let experienceRendering = appcues.container.resolve(ExperienceRendering.self)
        let currentExperienceId = experienceRendering.getCurrentExperienceData()?.id
        return .launchExperienceAction(fromExperienceID: currentExperienceId)
    }
}
