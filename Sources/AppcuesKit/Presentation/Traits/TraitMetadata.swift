//
//  TraitMetadata.swift
//  AppcuesKit
//
//  Created by Matt on 2023-02-06.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

public class TraitMetadata: NSObject {
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

    public subscript<T>(_ key: String) -> T? {
        newData[key] as? T
    }

    public subscript<T>(previous key: String) -> T? {
        previousData[key] as? T
    }
}
