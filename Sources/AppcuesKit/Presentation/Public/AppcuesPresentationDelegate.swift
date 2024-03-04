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

    /// Context of the experience.
    ///
    /// Either `"modal"` or the `frameID` of an ``AppcuesFrame``.
    public let renderContext: String

    internal init(id: String, name: String, renderContext: String) {
        self.id = id
        self.name = name
        self.renderContext = renderContext
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

    /// Notifies the delegate before an Appcues experience is dismissed.
    /// - Parameter metadata: Dictionary containing metadata about the experience.
    func experienceWillDisappear(metadata: AppcuesPresentationMetadata)

    /// Notifies the delegate after an Appcues experience is dismissed.
    /// - Parameter metadata: Dictionary containing metadata about the experience.
    func experienceDidDisappear(metadata: AppcuesPresentationMetadata)
}
