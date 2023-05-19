//
//  AppcuesContinueAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-17.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesContinueAction: AppcuesExperienceAction {
    struct Config: Decodable {
        let index: Int?
        let offset: Int?
        let stepID: UUID?
    }

    static let type = "@appcues/continue"

    private weak var appcues: Appcues?
    private let renderContext: RenderContext

    let stepReference: StepReference

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        appcues = configuration.appcues
        renderContext = configuration.renderContext

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

    init(appcues: Appcues?, renderContext: RenderContext, stepReference: StepReference) {
        self.appcues = appcues
        self.renderContext = renderContext
        self.stepReference = stepReference
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        let experienceRenderer = appcues.container.resolve(ExperienceRendering.self)
        experienceRenderer.show(step: stepReference, inContext: renderContext, completion: completion)
    }
}
