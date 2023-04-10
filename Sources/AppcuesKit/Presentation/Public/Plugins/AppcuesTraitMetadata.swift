//
//  AppcuesTraitMetadata.swift
//  AppcuesKit
//
//  Created by Matt on 2023-02-06.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

/// Stores values to be shared across ``AppcuesExperienceTrait`` instances. The instances may be the same trait applied to different steps,
/// or different traits that coordinate to create a more complex user interface.
public class AppcuesTraitMetadata: NSObject {
    private let newData: [String: Any?]
    private let previousData: [String: Any?]

    internal init(newData: [String: Any?], previousData: [String: Any?]) {
        self.newData = newData
        self.previousData = previousData
    }

    func viewAnimation(_ block: @escaping () -> Void) {
        guard let duration = newData["animationDuration"] as? TimeInterval,
                let easing = AppcuesStepTransitionAnimationTrait.Easing(metadataValue: newData["animationEasing"] as? String) else {
            block()
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: easing.curve) {
            block()
        }
    }

    func animationGroup() -> CAAnimationGroup? {
        guard let duration = newData["animationDuration"] as? TimeInterval,
              let easing = AppcuesStepTransitionAnimationTrait.Easing(metadataValue: newData["animationEasing"] as? String) else {
            return nil
        }

        let animationGroup = CAAnimationGroup()
        animationGroup.duration = duration
        animationGroup.timingFunction = CAMediaTimingFunction(name: easing.timingFunction)
        return animationGroup
    }

    /// Accesses the value associated with the given key for reading.
    public subscript<T>(_ key: String) -> T? {
        newData[key] as? T
    }

    /// Accesses the previous value associated with the given key for reading.
    ///
    /// This may be useful for coordinating transitions.
    public subscript<T>(previous key: String) -> T? {
        previousData[key] as? T
    }
}
