//
//  AppcuesContinueAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesContinueAction: ExperienceAction {
    struct Config: Decodable {
        let index: Int?
        let offset: Int?
        let stepID: UUID?
    }

    static let type = "@appcues/continue"

    let stepReference: StepReference

    required init?(configuration: ExperiencePluginConfiguration) {
        let config = configuration.decode(Config.self)
        if let index = config?.index {
            stepReference = .index(index)
        } else if let offset = config?.offset {
            stepReference = .offset(offset)
        } else if let stepID = config?.stepID {
            stepReference = .stepID(stepID)
        } else {
            // Default to continuing to next step
            stepReference = .offset(1)
        }
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.show(stepInCurrentExperience: stepReference, completion: completion)
    }
}
