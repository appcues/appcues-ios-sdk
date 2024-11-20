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
    private let traitInstances: [AppcuesExperienceTrait]
    let stepDecoratingTraitUpdater: (Int, Int?) async throws -> Void
    let steps: [Experience.Step.Child]
    let containerController: AppcuesExperienceContainerViewController
    let wrapperController: UIViewController
    let pageMonitor: AppcuesExperiencePageMonitor
    let presenter: () async throws -> Void
    let dismisser: () async -> Void

    internal init(
        traitInstances: [AppcuesExperienceTrait],
        stepDecoratingTraitUpdater: @escaping (Int, Int?) async throws -> Void,
        steps: [Experience.Step.Child],
        containerController: AppcuesExperienceContainerViewController,
        wrapperController: UIViewController,
        pageMonitor: AppcuesExperiencePageMonitor,
        presenter: @escaping () async throws -> Void,
        dismisser: @escaping () async -> Void
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
