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
    let triggeredBy: ExperienceTrigger?

    required init?(config: [String: Any]?) {
        if let experienceID = config?["experienceID"] as? String {
            self.experienceID = experienceID
            self.triggeredBy = nil
        } else {
            return nil
        }
    }

    init(experienceID: String, triggeredBy: ExperienceTrigger) {
        self.experienceID = experienceID

        // This is used when a flow is triggered as a post flow action from another flow.
        // The triggedBy value is set during the StateMachine processing of post-flow actions.
        self.triggeredBy = triggeredBy
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        let experienceRendering = appcues.container.resolve(ExperienceRendering.self)
        let experienceLoading = appcues.container.resolve(ExperienceLoading.self)

        let currentExperienceId = experienceRendering.getCurrentExperienceData()?.id

        // If no triggeredBy value is passedin, we know it was not triggered by a post-flow action
        // and we can use the standard `.launchExperienceAction` case, for a normal link within a flow
        // that launches another flow from a button, for example.
        let triggeredBy = self.triggeredBy ?? .launchExperienceAction(fromExperienceID: currentExperienceId)

        experienceLoading.load(experienceID: experienceID, published: true, triggeredBy: triggeredBy) { _  in completion() }
    }
}
