//
//  ExperienceTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

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

    /// Modify a view controller to include the trait.
    /// - Parameter experienceController: The view controller of the experience.
    /// - Parameter wrappingController: The view controller to wrap.
    /// - Returns: The view controller to be presented.
    ///
    /// The returned view controller should be `wrappingController` unless a custom container controller is being used.
    ///
    /// `experienceController` and `wrappingController` may be the same underlying `UIViewController`
    /// unless a trait has returned a a different controller.
    func apply(to experienceController: UIViewController, containedIn wrappingController: UIViewController) -> UIViewController
}
