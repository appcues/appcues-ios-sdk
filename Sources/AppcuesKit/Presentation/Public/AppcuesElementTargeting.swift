//
//  AppcuesElementTargeting.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/20/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

/// A type that describes an element targeting strategy for views in the application UI.
///
/// The SDK provides a default implementation for element targeting, but it can be overridden at initialization of the SDK
/// using the `Appcues.Config` option for `elementTargeting`.
@objc
public protocol AppcuesElementTargeting {
    /// Capture the layout hierarchy in the currently rendered screen of the application.
    /// - Returns: Root view element for the current screen, or `nil` if not available. The view element
    ///            contains sub-views recursively in the `children` property.
    func captureLayout() -> AppcuesViewElement?

    /// Create and return a selector implementation from configuration properties.
    /// - Parameter properties: Key-value collection of properties to identify a given view element.
    /// - Returns: The `AppcuesElementSelector` implementation for this element targeting strategy, based on
    ///            the given properties. If no applicable properties are found, the return value should be `nil`.
    func inflateSelector(from properties: [String: String]) -> AppcuesElementSelector?
}

internal extension AppcuesElementTargeting {
    // Default implementation that looks at the current view capture and finds any matches.
    // Used during targeted element experiences to find the position in the UI for the experience.
    func findMatches(for selector: AppcuesElementSelector) -> [(AppcuesViewElement, Int)]? {
        return captureLayout()?.viewsMatchingSelector(selector)
    }
}
