//
//  ContainerExperienceTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-13.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// An `ExperienceTrait` that wraps a `UIViewController`.
public protocol ContainerTrait {

    /// Modify a view controller to include the trait.
    /// - Parameter containerController: The container view controller of the experience.
    /// - Parameter wrappingController: The current wrapping view controller.
    /// - Returns: The view controller to be presented.
    ///
    /// The returned view controller should be `wrappingController` unless a custom wrapping controller is being used.
    ///
    /// `containerController` and `wrappingController` may be the same underlying `UIViewController`
    /// unless another trait has returned a a different controller.
    func apply(to containerController: UIViewController, wrappedBy wrappingController: UIViewController) -> UIViewController

}

/// A type that is an experience trait that wraps the Experience.
public typealias ContainerExperienceTrait = ExperienceTrait & ContainerTrait
