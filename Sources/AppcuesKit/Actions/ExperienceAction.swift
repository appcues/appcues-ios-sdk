//
//  ExperienceAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// A type that describes an action that can be triggered from an `Experience`.
public protocol ExperienceAction {

    /// The name of the action.
    ///
    /// Should be formatted `@org/name` (e.g. `@appcues/close`).
    static var type: String { get }

    /// Initializer from an `Experience.Action` data model.
    ///
    /// This initializer should verify the config has any required properties and return `nil` if not.
    init?(config: [String: Any]?)

    /// Execute the action.
    /// - Parameter appcues: The `Appcues` instance that displayed the instance triggering the action.
    func execute(inContext appcues: Appcues)
}
