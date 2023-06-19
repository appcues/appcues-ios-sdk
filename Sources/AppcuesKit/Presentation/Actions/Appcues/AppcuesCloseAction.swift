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
    private let renderContext: RenderContext

    private let markComplete: Bool

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        appcues = configuration.appcues
        renderContext = configuration.renderContext

        let config = configuration.decode(Config.self)
        markComplete = config?.markComplete ?? false
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.dismiss(inContext: renderContext, markComplete: markComplete) { _ in completion() }
    }
}
