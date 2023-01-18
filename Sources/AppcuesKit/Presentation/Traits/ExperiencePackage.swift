//
//  ExperiencePackage.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class ExperiencePackage {
    // References to the trait instances are held here to ensure they persist the lifetime of the experience being rendered.
    private let traitInstances: [ExperienceTrait]
    let stepDecoratingTraitUpdater: (Int, Int?) throws -> Void
    let steps: [Experience.Step.Child]
    let containerController: ExperienceContainerViewController
    let wrapperController: UIViewController
    let pageMonitor: PageMonitor
    let presenter: (_ completion: (() -> Void)?) throws -> Void
    let dismisser: (_ completion: (() -> Void)?) -> Void

    internal init(
        traitInstances: [ExperienceTrait],
        stepDecoratingTraitUpdater: @escaping (Int, Int?) throws -> Void,
        steps: [Experience.Step.Child],
        containerController: ExperienceContainerViewController,
        wrapperController: UIViewController,
        pageMonitor: PageMonitor,
        presenter: @escaping ((() -> Void)?) throws -> Void,
        dismisser: @escaping ((() -> Void)?) -> Void
    ) {
        self.traitInstances = traitInstances
        self.stepDecoratingTraitUpdater = stepDecoratingTraitUpdater
        self.steps = steps
        self.containerController = containerController
        self.wrapperController = wrapperController
        self.pageMonitor = pageMonitor
        self.presenter = presenter
        self.dismisser = dismisser
    }
}
