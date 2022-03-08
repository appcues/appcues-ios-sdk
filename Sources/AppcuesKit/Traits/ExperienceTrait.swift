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
    /// Must be unique and should be formatted `@org/name` (e.g. `@appcues/modal`).
    static var type: String { get }

    /// Initializer from an `Experience.Trait` data model.
    ///
    /// This initializer should verify the config has any required properties and return `nil` if not.
    init?(config: [String: Any]?)
}

/// A trait that modifies the `UIViewController` that encapsulates the contents of a specific step in the experience.
public protocol StepDecoratingTrait: ExperienceTrait {

    /// Modify the view controller for a step.
    /// - Parameter stepController: The `UIViewController` to modify.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func decorate(stepController: UIViewController) throws
}

/// A trait responsible for creating the `UIViewController` (specifically a ``ExperienceContainerViewController``) that holds the
/// experience step(s) being presented. The returned controller must call the ``ExperienceContainerLifecycleHandler``
/// methods at the appropriate times.
public protocol ContainerCreatingTrait: ExperienceTrait {

    /// Create the container controller for experience step(s).
    /// - Parameter stepControllers: Array of controllers being presented.
    /// - Parameter targetPageIndex: The index in the `stepControllers` that should be displayed with primary focus.
    /// - Returns: A `UIViewController` that contains the `stepControllers` as children.
    ///
    /// `stepControllers` is guaranteed to be non-empty and may frequently have only a single item.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func createContainer(for stepControllers: [UIViewController], targetPageIndex: Int) throws -> ExperienceContainerViewController
}

/// A trait that modifies the container view controller created by an ``ContainerCreatingTrait``.
public protocol ContainerDecoratingTrait: ExperienceTrait {

    /// Modify a container view controller.
    /// - Parameter containerController: The `UIViewController` to modify.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func decorate(containerController: ExperienceContainerViewController) throws
}

/// A trait that modifies the backdrop `UIView` that may be included in the presented experience.
public protocol BackdropDecoratingTrait: ExperienceTrait {

    /// Modify the backdrop view.
    /// - Parameter backdropView: The `UIView` to modify.
    ///
    /// Prefer adding a subview to `backdropView` over modifying `backdropView` itself where possible
    /// to preserve composability of multiple traits.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func decorate(backdropView: UIView) throws
}

/// A trait that creates a `UIViewController` that wraps the ``ExperienceContainerViewController``.
public protocol WrapperCreatingTrait: ExperienceTrait {

    /// Create a wrapper controller around a container controller.
    /// - Parameter containerController: The container controller.
    /// - Returns: A `UIViewController` that contains the `containerController` as a child.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func createWrapper(around containerController: ExperienceContainerViewController) throws -> UIViewController

    /// Add the decorated backdrop view to the wrapper.
    /// - Parameter backdropView: The backdrop.
    /// - Parameter wrapperController: The wrapper view controller.
    func addBackdrop(backdropView: UIView, to wrapperController: UIViewController)
}

/// A trait responsible for providing the ability to show and hide the experience.
public protocol PresentingTrait: ExperienceTrait {

    /// Shows the view controller for an experience.
    /// - Parameter viewController: The view controller to present.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func present(viewController: UIViewController) throws

    /// Removes the view controller for an experience.
    /// - Parameter viewController: The view controller to remove.
    /// - Parameter completion: The block to execute after the removal is completed.
    /// This block has no return value and takes no parameters. You may specify nil for this parameter.
    func remove(viewController: UIViewController, completion: (() -> Void)?)
}
