//
//  ControllerTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

/// A type that is an experience trait that modifies a `UIViewController`.
public typealias ControllerExperienceTrait = ExperienceTrait & ControllerTrait

/// An `ExperienceTrait` that modifies a `UIViewController`.
public protocol ControllerTrait {

    /// Modify a view controller to include the trait.
    /// - Parameter viewController: The view controller to apply the trait to.
    func apply(to viewController: UIViewController)
}
