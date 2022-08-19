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

    private weak var appcues: Appcues?

    private let markComplete: Bool
    private let experienceID: String?

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        appcues = configuration.appcues
        experienceID = configuration.experienceID

        let config = configuration.decode(Config.self)
        markComplete = config?.markComplete ?? false
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.dismissExperience(experienceID: experienceID, markComplete: markComplete) { _ in completion() }
    }
}
