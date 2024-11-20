//
//  AppcuesLaunchExperienceAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

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

        // Trigger is the current experienceID
        let renderContext = configuration.renderContext
        let experienceRendering = appcues?.container.resolve(ExperienceRendering.self)
        let currentExperienceID = experienceRendering?.experienceData(forContext: renderContext)?.id
        self.trigger = .launchExperienceAction(fromExperienceID: currentExperienceID)
    }

    init(appcues: Appcues?, experienceID: String, trigger: ExperienceTrigger) {
        self.appcues = appcues
        self.experienceID = experienceID
        self.trigger = trigger
    }

    func execute() async throws {
        guard let appcues = appcues else { throw AppcuesTraitError(description: "No appcues instance") }

        let contentLoader = appcues.container.resolve(ContentLoading.self)
        try await contentLoader.load(experienceID: experienceID, published: true, queryItems: [], trigger: trigger)
    }
}
