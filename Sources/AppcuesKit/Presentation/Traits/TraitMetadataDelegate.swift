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
