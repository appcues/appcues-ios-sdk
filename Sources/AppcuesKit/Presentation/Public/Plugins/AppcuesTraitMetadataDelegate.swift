//
//  AppcuesTraitMetadataDelegate.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

/// Methods for managing data to be shared across trait instances.
@objc
internal class AppcuesTraitMetadataDelegate: NSObject {
    private var metadata: [String: Any?] = [:]
    private var previousMetadata: [String: Any?] = [:]

    private var nonAnimatingHandlers: [String: (AppcuesTraitMetadata) -> Void] = [:]
    private var viewAnimatingHandlers: [String: (AppcuesTraitMetadata) -> Void] = [:]

    /// Sets metadata values.
    /// - Parameter newDict: Key/value pairs to update in the metadata dictionary.
    ///
    /// Handlers are not automatically notified of changes. To refresh the handlers, call ``publish()``.
    internal func set(_ newDict: [String: Any?]) {
        metadata = metadata.merging(newDict)
    }

    /// Removes metadata values.
    /// - Parameter keys: Keys to remove from the metadata dictionary.
    internal func unset(keys: [String]) {
        keys.forEach {
            metadata.removeValue(forKey: $0)
        }
    }

    /// Publishes the current metadata values to all registered handlers.
    ///
    /// Updates are automatically published after a step change in an experience.
    ///
    /// There are no guarantees about the order in which handlers will be called.
    internal func publish() {
        let traitMetadata = AppcuesTraitMetadata(newData: metadata, previousData: previousMetadata)

        nonAnimatingHandlers.forEach { _, observer in observer(traitMetadata) }

        traitMetadata.viewAnimation {
            self.viewAnimatingHandlers.forEach { _, block in block(traitMetadata) }
        }

        previousMetadata = metadata
    }

    /// Adds an handler to the dispatch table.
    /// - Parameters:
    ///   - key: The key for the handler block.
    ///   - animating: Whether the observer should be called in a `UIView.animate` block.
    ///   - handler: Block to execute on publish.
    internal func registerHandler(for key: String, animating: Bool, handler: @escaping (AppcuesTraitMetadata) -> Void) {
        removeHandler(for: key)

        if animating {
            viewAnimatingHandlers[key] = handler
        } else {
            nonAnimatingHandlers[key] = handler
        }
    }

    /// Removes matching handlers from the dispatch table.
    /// - Parameter key: Key to remove.
    internal func removeHandler(for key: String) {
        nonAnimatingHandlers.removeValue(forKey: key)
        viewAnimatingHandlers.removeValue(forKey: key)
    }

}
