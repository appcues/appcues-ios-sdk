//
//  ContainerTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

/// A type that is an experience trait that wraps the Experience.
public typealias ContainerExperienceTrait = ExperienceTrait & ContainerTrait

/// An `ExperienceTrait` that wraps a `UIViewController`.
public protocol ContainerTrait {

    /// Modify a view controller to include the trait.
    /// - Parameter viewController: The view controller to wrap.
    /// - Returns: The container view controller that includes `viewController` as a child.
    func apply(to viewController: UIViewController) -> UIViewController
}
