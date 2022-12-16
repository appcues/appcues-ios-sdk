//
//  TraitMetadataDelegate.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// Methods for managing data to be shared across trait instances.
@objc
public class TraitMetadataDelegate: NSObject {
    private var metadata: [String: Any?] = [:]
    private var previousMetadata: [String: Any?] = [:]

    private var nonAnimatingSubscribers: [String: (TraitMetadata) -> Void] = [:]
    private var viewAnimatingSubscribers: [String: (TraitMetadata) -> Void] = [:]

    public func set(_ newDict: [String: Any?]) {
        metadata = metadata.merging(newDict)
    }

    public func unset(keys: [String]) {
        keys.forEach {
            metadata.removeValue(forKey: $0)
        }
    }

    // Updates are automatically published after a step change.
    // This can be used to manually publish updates in other cases.
    public func publish() {
        let traitMetadata = TraitMetadata(newData: metadata, previousData: previousMetadata)

        nonAnimatingSubscribers.forEach { _, observer in observer(traitMetadata) }

        traitMetadata.viewAnimation {
            self.viewAnimatingSubscribers.forEach { _, block in block(traitMetadata) }
        }

        previousMetadata = metadata
    }

    public func registerHandler(for key: String, animating: Bool, observer: @escaping (TraitMetadata) -> Void) {
        if animating {
            viewAnimatingSubscribers[key] = observer
        } else {
            nonAnimatingSubscribers[key] = observer
        }
    }

    public func removeHandler(for key: String) {
        nonAnimatingSubscribers.removeValue(forKey: key)
        viewAnimatingSubscribers.removeValue(forKey: key)
    }

}

public class TraitMetadata: NSObject {
    private let newData: [String: Any?]
    private let previousData: [String: Any?]

    internal init(newData: [String: Any?], previousData: [String: Any?]) {
        self.newData = newData
        self.previousData = previousData
    }

    func viewAnimation(_ block: @escaping () -> Void) {
        guard let duration = newData["animationDuration"] as? TimeInterval,
                let easing = newData["animationEasing"] as? AppcuesStepTransitionAnimationTrait.Easing else {
            block()
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: easing.curve) {
            block()
        }
    }

    func basicAnimation(keyPath: String?) -> CABasicAnimation? {
        guard let duration = newData["animationDuration"] as? TimeInterval,
              let easing = newData["animationEasing"] as? AppcuesStepTransitionAnimationTrait.Easing else {
            return nil
        }

        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: easing.timingFunction)
        return animation
    }

    public subscript<T>(_ key: String) -> T? {
        newData[key] as? T
    }

    public subscript<T>(previous key: String) -> T? {
        previousData[key] as? T
    }

    public subscript<T>(pair key: String) -> (new: T?, previous: T?) {
        (newData[key] as? T, previousData[key] as? T)
    }
}
