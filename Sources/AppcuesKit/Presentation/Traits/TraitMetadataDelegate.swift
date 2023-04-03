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

    private var nonAnimatingHandlers: [String: (TraitMetadata) -> Void] = [:]
    private var viewAnimatingHandlers: [String: (TraitMetadata) -> Void] = [:]

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

        nonAnimatingHandlers.forEach { _, observer in observer(traitMetadata) }

        traitMetadata.viewAnimation {
            self.viewAnimatingHandlers.forEach { _, block in block(traitMetadata) }
        }

        previousMetadata = metadata
    }

    public func registerHandler(for key: String, animating: Bool, handler: @escaping (TraitMetadata) -> Void) {
        if animating {
            viewAnimatingHandlers[key] = handler
        } else {
            nonAnimatingHandlers[key] = handler
        }
    }

    public func removeHandler(for key: String) {
        nonAnimatingHandlers.removeValue(forKey: key)
        viewAnimatingHandlers.removeValue(forKey: key)
    }

}
