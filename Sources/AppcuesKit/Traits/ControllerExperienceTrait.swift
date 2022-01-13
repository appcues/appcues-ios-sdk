//
//  ControllerExperienceTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-13.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// An `ExperienceTrait` that modifies a `UIViewController`.
public protocol ControllerTrait {

    /// Modify a view controller to include the trait.
    /// - Parameter viewController: The view controller to apply the trait to.
    func apply(to viewController: UIViewController)
}

/// A type that is an experience trait that modifies a `UIViewController`.
public typealias ControllerExperienceTrait = ExperienceTrait & ControllerTrait
