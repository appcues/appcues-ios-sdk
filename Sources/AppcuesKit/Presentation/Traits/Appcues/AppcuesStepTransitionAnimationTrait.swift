//
//  AppcuesStepTransitionAnimationTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class AppcuesStepTransitionAnimationTrait: AppcuesContainerDecoratingTrait {
    struct Config: Decodable {
        let duration: Int?
        let easing: Easing?
    }

    static var type: String = "@appcues/step-transition-animation"

    weak var metadataDelegate: AppcuesTraitMetadataDelegate?

    private let duration: TimeInterval
    private let easing: Easing

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        let config = configuration.decode(Config.self)
        self.duration = Double(config?.duration ?? 300) / 1_000
        self.easing = config?.easing ?? .linear
    }

    @MainActor
    func decorate(containerController: AppcuesExperienceContainerViewController) throws {
        metadataDelegate?.set([
            "animationDuration": duration,
            // Use String value so it can be read by third party traits.
            "animationEasing": easing.rawValue
        ])
    }

    @MainActor
    func undecorate(containerController: AppcuesExperienceContainerViewController) throws {
        metadataDelegate?.unset(keys: [ "animationDuration", "animationEasing" ])
    }
}

extension AppcuesStepTransitionAnimationTrait {

    enum Easing: String, Decodable {
        case linear, easeIn, easeOut, easeInOut

        var curve: UIView.AnimationOptions {
            switch self {
            case .linear:
                return .curveLinear
            case .easeIn:
                return .curveEaseIn
            case .easeOut:
                return .curveEaseOut
            case .easeInOut:
                return .curveEaseInOut
            }
        }

        var timingFunction: CAMediaTimingFunctionName {
            switch self {
            case .linear:
                return .linear
            case .easeIn:
                return .easeIn
            case .easeOut:
                return .easeOut
            case .easeInOut:
                return .easeInEaseOut
            }
        }

        init?(metadataValue: String?) {
            guard let metadataValue = metadataValue else { return nil }
            self.init(rawValue: metadataValue)
        }
    }
}
