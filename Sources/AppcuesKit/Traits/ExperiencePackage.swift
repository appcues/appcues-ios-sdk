//
//  ExperiencePackage.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal struct ExperiencePackage {
    let steps: [Experience.Step]
    let containerController: ExperienceStepContainer
    let wrapperController: UIViewController
    let presenter: () throws -> Void
    let dismisser: () -> Void
}
