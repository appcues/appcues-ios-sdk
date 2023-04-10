//
//  AppcuesCloseAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 13.0, *)
internal class AppcuesCloseAction: AppcuesExperienceAction {
    struct Config: Decodable {
        let markComplete: Bool
    }

    static let type = "@appcues/close"

    private let markComplete: Bool

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        let config = configuration.decode(Config.self)
        markComplete = config?.markComplete ?? false
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.dismissCurrentExperience(markComplete: markComplete) { _ in completion() }
    }
}
