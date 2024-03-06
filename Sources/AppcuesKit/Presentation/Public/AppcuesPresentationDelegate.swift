//
//  AppcuesPresentationDelegate.swift
//  AppcuesKit
//
//  Created by Matt on 2024-03-04.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation

/// Metadata information for experiences in ``AppcuesPresentationDelegate``.
@objc
public class AppcuesPresentationMetadata: NSObject {
    /// Appcues ID of the experience.
    public let id: String

    /// Name of the experience.
    public let name: String

    /// True if the experience is presented as an overlay. Includes modals, tooltips, and slideouts.
    public let isOverlay: Bool

    /// True if the experience is presented in an embe frame.
    public let isEmbed: Bool

    /// Frame ID of the experience. Non-nil when `isEmbed == true`
    public let frameID: String?

    internal init(id: String, name: String, isOverlay: Bool, isEmbed: Bool, frameID: String?) {
        self.id = id
        self.name = name
        self.isOverlay = isOverlay
        self.isEmbed = isEmbed
        self.frameID = frameID
    }
}

/// A set of methods that allow you to control and respond to Appcues experiences being displayed changes in your app.
@objc
public protocol AppcuesPresentationDelegate: AnyObject {
    /// Asks the delegate for permission to display the Appcues experience.
    /// - Returns: `true` to allow the SDK to display the experience, `false` to refuse the presentation.
    func canDisplayExperience(metadata: AppcuesPresentationMetadata) -> Bool

    /// Notifies the delegate before an Appcues experience is presented.
    /// - Parameter metadata: Dictionary containing metadata about the experience.
    func experienceWillAppear(metadata: AppcuesPresentationMetadata)

    /// Notifies the delegate after an Appcues experience is presented.
    /// - Parameter metadata: Dictionary containing metadata about the experience.
    func experienceDidAppear(metadata: AppcuesPresentationMetadata)

    /// Notifies the delegate after a step change in a presented Appcues experience.
    /// - Parameter metadata: Dictionary containing metadata about the experience.
    func experienceStepDidChange(metadata: AppcuesPresentationMetadata)

    /// Notifies the delegate before an Appcues experience is dismissed.
    /// - Parameter metadata: Dictionary containing metadata about the experience.
    func experienceWillDisappear(metadata: AppcuesPresentationMetadata)

    /// Notifies the delegate after an Appcues experience is dismissed.
    /// - Parameter metadata: Dictionary containing metadata about the experience.
    func experienceDidDisappear(metadata: AppcuesPresentationMetadata)
}
