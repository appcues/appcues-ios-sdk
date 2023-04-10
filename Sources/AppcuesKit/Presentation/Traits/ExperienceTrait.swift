//
//  ExperienceTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

// swiftlint:disable file_types_order

/// Context in which a trait can be applied.
@objc
public enum ExperienceTraitLevel: Int {
    /// A trait to be applied to the entire experiene.
    case experience
    /// A trait to be applied to a group of steps in  an experience.
    case group
    /// A trait to be applied to a single step in an experiene.
    case step
}

/// A type that describes a trait of an `Experience`.
@objc
public protocol ExperienceTrait {

    /// The name of the trait.
    ///
    /// Must be unique and should be formatted `@org/name` (e.g. `@appcues/modal`).
    static var type: String { get }

    /// The object that provides access to data shared across trait instances.
    weak var metadataDelegate: TraitMetadataDelegate? { get set }

    /// Initializer from an `Experience.Trait` data model.
    ///
    /// This initializer should verify the config has any required properties and return `nil` if not.
    init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel)
}

/// A trait that modifies the `UIViewController` that encapsulates the contents of a specific step in the experience.
@objc
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
@objc
public protocol ContainerCreatingTrait: ExperienceTrait {

    /// Create the container controller for experience step(s).
    /// - Parameter stepControllers: Array of controllers being presented.
    /// - Parameter pageMonitor: The object that maintains the page state metadata for the container.
    /// - Returns: A `UIViewController` that contains the `stepControllers` as children.
    ///
    /// `stepControllers` is guaranteed to be non-empty and may frequently have only a single item.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func createContainer(for stepControllers: [UIViewController], with pageMonitor: PageMonitor) throws -> ExperienceContainerViewController
}

/// A trait that modifies the container view controller created by an ``ContainerCreatingTrait``.
@objc
public protocol ContainerDecoratingTrait: ExperienceTrait {

    /// Modify a container view controller.
    /// - Parameter containerController: The `ExperienceContainerViewController` to modify.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func decorate(containerController: ExperienceContainerViewController) throws

    /// Remove the decoratation from a container view controller.
    /// - Parameter containerController: The `ExperienceContainerViewController` to modify.
    ///
    /// A call to ``undecorate(containerController:)`` should remove all modifications performed by ``decorate(containerController:)``.
    ///
    /// This method will only be called for traits applied at the step level when navigating between steps in a group.
    ///
    /// If this method cannot properly remove the trait behavior, it may throw an error of type ``TraitError``,
    /// ending presentation of the experience.
    func undecorate(containerController: ExperienceContainerViewController) throws
}

/// A trait that modifies the backdrop `UIView` that may be included in the presented experience.
@objc
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

    /// Remove the decoratation from a backdrop view.
    /// - Parameter backdropView: The `UIView` to modify.
    ///
    /// A call to ``undecorate(backdropView:)`` should remove all modifications performed by ``decorate(backdropView:)``.
    ///
    /// This method will only be called for traits applied at the step level when navigating between steps in a group.
    ///
    /// If this method cannot properly remove the trait behavior, it may throw an error of type ``TraitError``,
    /// ending presentation of the experience.
    func undecorate(backdropView: UIView) throws
}

/// A trait that creates a `UIViewController` that wraps the ``ExperienceContainerViewController``.
@objc
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
@objc
public protocol PresentingTrait: ExperienceTrait {

    /// Shows the view controller for an experience.
    /// - Parameter viewController: The view controller to present.
    /// - Parameter completion: The block to execute after the presentation is completed.
    ///
    /// If this method cannot properly apply the trait behavior, it may throw an error of type ``TraitError``,
    /// ending the attempt to display the experience.
    func present(viewController: UIViewController, completion: (() -> Void)?) throws

    /// Removes the view controller for an experience.
    /// - Parameter viewController: The view controller to remove.
    /// - Parameter completion: The block to execute after the removal is completed.
    /// This block has no return value and takes no parameters. You may specify nil for this parameter.
    func remove(viewController: UIViewController, completion: (() -> Void)?)
}
