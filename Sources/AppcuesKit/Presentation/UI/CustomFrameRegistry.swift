//
//  CustomFrameRegistry.swift
//  AppcuesKit
//
//  Created by Matt on 2023-05-19.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

public protocol AppcuesCustomFrameViewController: UIViewController {
    init?(configuration: AppcuesExperiencePluginConfiguration)
}

@available(iOS 13.0, *)
extension AppcuesFrame.AppcuesFrameVC: AppcuesCustomFrameViewController {
    struct Config: Decodable {
        let frameID: String
    }

    convenience init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }

        self.init()
        configuration.appcues?.register(frameID: config.frameID, for: self.frameView, on: self)
    }
}

@available(iOS 13.0, *)
internal class CustomFrameRegistry {
    private var registeredFrames: [String: AppcuesCustomFrameViewController.Type] = [:]
    private weak var appcues: Appcues?

    init(container: DIContainer) {
        self.appcues = container.owner

        register(frame: "AppcuesFrame", type: AppcuesFrame.AppcuesFrameVC.self)
    }

    func register(frame identifier: String, type: AppcuesCustomFrameViewController.Type) {
        guard registeredFrames[identifier] == nil else {
            appcues?.config.logger.error("Custom frame with identifier %{public}@ is already registered.", identifier)
            return
        }

        registeredFrames[identifier] = type
    }

    func embed(
        for model: ExperienceComponent.CustomFrameModel,
        renderContext: RenderContext
    ) -> (AppcuesCustomFrameViewController.Type, AppcuesExperiencePluginConfiguration)? {
        guard let type = registeredFrames[model.identifier] else { return nil }

        return(
            type,
            AppcuesExperiencePluginConfiguration(
                model.configDecoder,
                level: .step,
                renderContext: renderContext,
                appcues: appcues
            )
        )
    }
}
