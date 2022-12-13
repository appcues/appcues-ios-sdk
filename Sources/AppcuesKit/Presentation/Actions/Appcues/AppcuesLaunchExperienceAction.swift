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

    required init?(config: DecodingExperienceConfig) {
        if let experienceID: String = config["experienceID"] {
            self.experienceID = experienceID
        } else {
            return nil
        }
    }

    init(experienceID: String) {
        self.experienceID = experienceID
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        appcues.show(experienceID: experienceID) { _, _  in completion() }
    }
}
