//
//  UIKitElementTargeting.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/20/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

// UIKit selector implementation that uses accessibilityIdentifier,
// accessibilityLabel, and tag data from the underlying UIView to identify elements.
internal class UIKitElementSelector: AppcuesElementSelector {
    private enum CodingKeys: String, CodingKey {
        case appcuesID
        case accessibilityIdentifier
        case accessibilityLabel
        case tag
    }

    let accessibilityIdentifier: String?
    let tag: String?
    let appcuesID: String?

    init?(appcuesID: String?, accessibilityIdentifier: String?, accessibilityLabel: String?, tag: String?) {
        // must have at least one identifiable property to be a valid selector
        if appcuesID == nil && accessibilityIdentifier == nil && accessibilityLabel == nil && tag == nil {
            return nil
        }

        self.appcuesID = appcuesID
        self.accessibilityIdentifier = accessibilityIdentifier
        self.tag = tag

        super.init()

        // note: accessibilityLabel is inherited from base type NSObject and used here
        self.accessibilityLabel = accessibilityLabel

    }

    override func evaluateMatch(for target: AppcuesElementSelector) -> Int {
        guard let other = target as? UIKitElementSelector else {
            return 0
        }

        // weight the selector property matches by how distinct they are considered
        var weight = 0

        if appcuesID != nil && appcuesID == other.appcuesID {
            weight += 10_000
        }

        if accessibilityIdentifier != nil && accessibilityIdentifier == other.accessibilityIdentifier {
            weight += 10_000
        }

        if tag != nil && tag == other.tag {
            weight += 1_000
        }

        if accessibilityLabel != nil && accessibilityLabel == other.accessibilityLabel {
            weight += 100
        }

        return weight
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let appcuesID = appcuesID, !appcuesID.isEmpty {
            try container.encode(appcuesID, forKey: .appcuesID)
        }
        if let accessibilityIdentifier = accessibilityIdentifier, !accessibilityIdentifier.isEmpty {
            try container.encode(accessibilityIdentifier, forKey: .accessibilityIdentifier)
        }
        if let accessibilityLabel = accessibilityLabel, !accessibilityLabel.isEmpty {
            try container.encode(accessibilityLabel, forKey: .accessibilityLabel)
        }
        if let tag = tag, !tag.isEmpty {
            try container.encode(tag, forKey: .tag)
        }
    }
}

// UIKit implementation of element targeting that captures the UIView hierarchy for the current UIWindow,
// and identifies applicable views with a UIKitElementSelector.
@available(iOS 13.0, *)
internal class UIKitElementTargeting: AppcuesElementTargeting {
    // Inject a window for testing purposes
    var window: UIWindow?

    func captureLayout() -> AppcuesViewElement? {
        let captureWindow = (window ?? UIApplication.shared.windows.first { !$0.isAppcuesWindow })
        return captureWindow?.asViewElement()
    }

    func inflateSelector(from properties: [String: String]) -> AppcuesElementSelector? {
        return UIKitElementSelector(
            appcuesID: properties["appcuesID"],
            accessibilityIdentifier: properties["accessibilityIdentifier"],
            accessibilityLabel: properties["accessibilityLabel"],
            tag: properties["tag"]
        )
    }
}

internal extension UIView {
    var appcuesSelector: UIKitElementSelector? {
        return UIKitElementSelector(
            appcuesID: (self as? AppcuesTargetView)?.appcuesID,
            accessibilityIdentifier: accessibilityIdentifier,
            accessibilityLabel: accessibilityLabel,
            tag: tag != 0 ? "\(self.tag)" : nil
        )
    }

    func asViewElement() -> AppcuesViewElement? {
        return self.asViewElement(in: self.bounds)
    }

    private func asViewElement(in bounds: CGRect) -> AppcuesViewElement? {
        let absolutePosition = self.convert(self.bounds, to: nil)

        // discard views that are not visible in the screenshot image
        guard absolutePosition.intersects(bounds) else { return nil }

        let children: [AppcuesViewElement] = self.subviews.compactMap {
            // discard hidden views and subviews within
            guard !$0.isHidden else { return nil }
            return $0.asViewElement(in: bounds)
        }

        return AppcuesViewElement(
            x: absolutePosition.origin.x,
            y: absolutePosition.origin.y,
            width: absolutePosition.width,
            height: absolutePosition.height,
            type: "\(type(of: self))",
            selector: appcuesSelector,
            children: children.isEmpty ? nil : children
        )
    }
}
