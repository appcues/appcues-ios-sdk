//
//  AppcuesLaunchExperienceAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct AppcuesLaunchExperienceAction: ExperienceAction {
    static let type = "@appcues/launch-experience"

    let experienceID: String

    init?(config: [String: Any]?) {
        if let experienceID = config?["experienceID"] as? String {
            self.experienceID = experienceID
        } else {
            return nil
        }
    }

    func execute(inContext appcues: Appcues, completion: @escaping () -> Void) {
        // Set an observer for when the experience is eventually shown
        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.add(eventDelegate: ExperienceRenderer.OneTimeEventDelegate(on: .displayedStep, completion: completion))

        // TODO: there's a scenario here where `completion` doesn't get called:
        // If the experience fails to load, the ExperienceRenderer never gets involved and we get stuck on this action.

        appcues.show(experienceID: experienceID)
    }
}
