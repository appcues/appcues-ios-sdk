//
//  ExperienceStepContainer.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

public protocol ExperienceStepContainer: UIViewController {
    var lifecycleHandler: ExperienceContainerLifecycleHandler? { get set }

    func navigate(to pageIndex: Int)
}
