//
//  ExperienceTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

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
