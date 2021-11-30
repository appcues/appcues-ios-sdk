//
//  AppcuesSequentialContinueAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct AppcuesSequentialContinueAction: ExperienceAction {
    static let type = "@appcues/sequential.continue"

    let stepReference: ExperienceRenderer.StepReference

    init?(config: [String: Any]?) {
        if let index = config?["index"] as? Int {
            stepReference = .index(index)
        } else if let offset = config?["offset"] as? Int {
            stepReference = .offset(offset)
        } else {
            // Default to continuing to next step
            stepReference = .offset(1)
        }
    }

    func execute(inContext appcues: Appcues) {
        let experienceRenderer = appcues.container.resolve(ExperienceRenderer.self)
        experienceRenderer.show(stepInCurrentExperience: stepReference)
    }
}
