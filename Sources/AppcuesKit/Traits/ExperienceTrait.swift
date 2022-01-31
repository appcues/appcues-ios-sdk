//
//  ExperienceTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

// swiftlint:disable file_types_order

/// A type that describes a trait of an `Experience`.
public protocol ExperienceTrait {

    /// The name of the trait.
    ///
    /// Should be formatted `@org/name` (e.g. `@appcues/modal`).
    static var type: String { get }

    /// Initializer from an `Experience.Trait` data model.
    ///
    /// This initializer should verify the config has any required properties and return `nil` if not.
    init?(config: [String: Any]?)
}

 internal protocol JoiningTrait: ExperienceTrait {
    func join(initialStep stepIndex: Int, in experience: Experience) -> [Experience.Step]
}

public protocol StepDecoratingTrait: ExperienceTrait {
    func decorate(stepController: UIViewController) throws
}

public protocol ContainerCreatingTrait: ExperienceTrait {
    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceStepContainer
}

public protocol ContainerDecoratingTrait: ExperienceTrait {
    func decorate(containerController: ExperienceStepContainer) throws
}

public protocol BackdropDecoratingTrait: ExperienceTrait {
    func decorate(backdropView: UIView) throws
}

public protocol WrapperCreatingTrait: ExperienceTrait {
    func createWrapper(around containerController: ExperienceStepContainer) throws -> UIViewController
    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController)
}

public protocol PresentingTrait: ExperienceTrait {
    func present(viewController: UIViewController) throws
    func remove(viewController: UIViewController)
}

public protocol ConditionalGroupingTrait: ExperienceTrait {
    var groupID: String { get }
}
