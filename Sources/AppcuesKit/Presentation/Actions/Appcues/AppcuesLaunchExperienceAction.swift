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
    private let trigger: ExperienceTrigger

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.experienceID = config.experienceID

        let renderContext = configuration.renderContext
        let experienceRendering = appcues?.container.resolve(ExperienceRendering.self)
        let currentExperience = experienceRendering?.experienceData(forContext: renderContext)
        self.trigger = .launchExperienceAction(
            fromExperienceID: currentExperience?.id,
            campaignId: currentExperience?.campaignId,
            tacticId: currentExperience?.tacticId
        )
    }

    init(appcues: Appcues?, experienceID: String, trigger: ExperienceTrigger) {
        self.appcues = appcues
        self.experienceID = experienceID
        self.trigger = trigger
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else {
            return completion()
        }

        let contentLoader = appcues.container.resolve(ContentLoading.self)
        contentLoader.load(experienceID: experienceID, published: true, queryItems: [], trigger: trigger) { _  in
            completion()
        }
    }
}
