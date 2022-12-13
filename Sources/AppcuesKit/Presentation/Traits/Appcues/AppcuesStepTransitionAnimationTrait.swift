//
//  AppcuesStepTransitionAnimationTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class AppcuesStepTransitionAnimationTrait: ContainerDecoratingTrait {

    static var type: String = "@appcues/step-transition-animation"

    weak var metadataDelegate: TraitMetadataDelegate?

    let duration: TimeInterval
    let easing: Easing

    required init?(config: DecodingExperienceConfig, level: ExperienceTraitLevel) {
        self.duration = config["duration"] ?? 0.3
        self.easing = config["easing"] ?? .linear
    }

    func decorate(containerController: ExperienceContainerViewController) throws {
        metadataDelegate?.set([
            "animationDuration": duration,
            "animationEasing": easing
        ])
    }

    func undecorate(containerController: ExperienceContainerViewController) throws {
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
    }
}
