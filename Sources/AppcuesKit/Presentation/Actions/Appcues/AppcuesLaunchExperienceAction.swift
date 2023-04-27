//
//  AppcuesLaunchExperienceAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesLaunchExperienceAction: AppcuesExperienceAction {
    struct Config: Decodable {
        let experienceID: String
    }

    static let type = "@appcues/launch-experience"

    private weak var appcues: Appcues?

    let experienceID: String
    private let trigger: ExperienceTrigger?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.experienceID = config.experienceID
        self.trigger = nil
    }

    init(appcues: Appcues?, experienceID: String, trigger: ExperienceTrigger) {
        self.appcues = appcues
        self.experienceID = experienceID

        // This is used when a flow is triggered as a post flow action from another flow.
        // The trigger value is set during the StateMachine processing of the post-flow actions.
        self.trigger = trigger
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else {
            return completion()
        }

        let experienceLoading = appcues.container.resolve(ExperienceLoading.self)

        // If no trigger value is passed in, we know it was not triggered by a post-flow action
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
