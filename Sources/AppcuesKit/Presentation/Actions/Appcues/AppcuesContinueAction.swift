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
    static let type = "@appcues/continue"

    let stepReference: StepReference

    required init?(config: [String: Any]?) {
        if let index = config?["index"] as? Int {
            stepReference = .index(index)
        } else if let offset = config?["offset"] as? Int {
            stepReference = .offset(offset)
        } else if let stepID = UUID(uuidString: config?["stepID"] as? String ?? "") {
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
