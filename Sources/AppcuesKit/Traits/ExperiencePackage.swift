//
//  ExperiencePackage.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal struct ExperiencePackage {
    // References to the trait instances are held here to ensure they persist the lifetime of the experience being rendered.
    private let traitInstances: [ExperienceTrait]
    let steps: [Experience.Step.Child]
    let containerController: ExperienceContainerViewController
    let wrapperController: UIViewController
    let presenter: () throws -> Void
    let dismisser: (_ completion: (() -> Void)?) -> Void

    internal init(
        traitInstances: [ExperienceTrait],
        steps: [Experience.Step.Child],
        containerController: ExperienceContainerViewController,
        wrapperController: UIViewController,
        presenter: @escaping () throws -> Void,
        dismisser: @escaping ((() -> Void)?) -> Void
    ) {
        self.traitInstances = traitInstances
        self.steps = steps
        self.containerController = containerController
        self.wrapperController = wrapperController
        self.presenter = presenter
        self.dismisser = dismisser
    }
}
