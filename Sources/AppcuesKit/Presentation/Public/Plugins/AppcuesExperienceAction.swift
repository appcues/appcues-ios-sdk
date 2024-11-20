//
//  AppcuesExperienceAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// A type that describes an action that can be triggered from an `Experience`.
@objc
internal protocol AppcuesExperienceAction {

    /// The name of the action.
    ///
    /// Must be unique and should be formatted `@org/name` (e.g. `@appcues/close`).
    static var type: String { get }

    /// Initializer from an `Experience.Action` data model.
    ///
    /// This initializer should verify the config has any required properties and return `nil` if not.
    init?(configuration: AppcuesExperiencePluginConfiguration)

    /// Execute the action.
    func execute() async throws
}
