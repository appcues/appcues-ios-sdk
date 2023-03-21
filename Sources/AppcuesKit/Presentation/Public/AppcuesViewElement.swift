//
//  AppcuesViewElement.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/22/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

/// Represents a view in the layout hierarchy of the application.
///
/// The view information provided in this structure provides screen capture metadata to Appcues
/// servers that can be used for element targeted experiences. The layout information is used by the
/// Appcues Mobile Builder to select and target UI elements, and used by the Appcues iOS SDK to
/// position experience content relative to targeted elements.
@objc
public class AppcuesViewElement: NSObject, Encodable {
    /// Auto-generated unique ID for the view.
    let id = UUID().appcuesFormatted

    /// The x-coordinate for view position, with origin in the upper-left corner.
    let x: CGFloat

    /// The y-coordinate for view position, with origin is in the upper-left corner.
    let y: CGFloat

    /// The width of the view.
    let width: CGFloat

    /// The height of the view.
    let height: CGFloat

    /// A value representing the type of the view.
    let type: String

    /// The element selector details that can be used to target content to this view. The selector structure
    /// depends on the UI toolkit in use. If no identifiable properties exist for this view, this selector value should be `nil`.
    let selector: AppcuesElementSelector?

    /// The sub-views contained within this view, if any.
    let children: [AppcuesViewElement]?

    /// Creates an instance of an AppcuesViewElement.
    /// - Parameters:
    ///   - x: The x-coordinate for view position, with origin in the upper-left corner.
    ///   - y: The y-coordinate for view position, with origin is in the upper-left corner.
    ///   - width: The width of the view.
    ///   - height: The height of the view.
    ///   - type: The type of the view.
    ///   - selector: The selector to idenfify the view.
    ///   - children: The sub-views contained within the view.
    @objc
    public init(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        type: String,
        selector: AppcuesElementSelector?,
        children: [AppcuesViewElement]?
    ) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.type = type
        self.selector = selector
        self.children = children
    }
}

internal extension AppcuesViewElement {
    // Used internally by the SDK to find all views, recursively, that have at least a
    // partial match with the given selector. Used to find the position of an element
    // targeted experience.
    func viewsMatchingSelector(_ target: AppcuesElementSelector) -> [AppcuesViewElement] {
        var views: [AppcuesViewElement] = []

        if let current = selector {
            if current.evaluateMatch(for: target) > 0 {
                views.append(self)
            }
        }

        children?.forEach { child in
            views.append(contentsOf: child.viewsMatchingSelector(target))
        }

        return views
    }
}
