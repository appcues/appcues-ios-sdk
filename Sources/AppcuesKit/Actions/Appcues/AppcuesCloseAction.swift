//
//  AppcuesCloseAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal struct AppcuesCloseAction: ExperienceAction {

    static let type = "@appcues/close"

    init?(config: [String: Any]?) {
        // no config expected
    }

    func execute(inContext appcues: Appcues, completion: @escaping () -> Void) {
        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.dismissCurrentExperience(completion: completion)
    }
}
