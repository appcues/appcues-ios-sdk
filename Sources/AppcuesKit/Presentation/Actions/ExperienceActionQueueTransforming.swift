//
//  ExperienceActionQueueTransforming.swift
//  AppcuesKit
//
//  Created by Matt on 2022-09-28.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

/// An `ExperienceAction` that performs modifications of the action queue executed following an interaction in an experience.
@objc
internal protocol ExperienceActionQueueTransforming: AppcuesExperienceAction {

    /// Modify the queue of actions executed in an experience.
    /// - Parameters:
    ///   - queue: The current queue of actions.
    ///   - index: The index of the current action in the `queue`.
    ///   - appcues: The `Appcues` instance that displayed the experience triggering the action.
    /// - Returns: The updated queue.
    func transformQueue(_ queue: [AppcuesExperienceAction], index: Int, inContext appcues: Appcues) -> [AppcuesExperienceAction]
}
