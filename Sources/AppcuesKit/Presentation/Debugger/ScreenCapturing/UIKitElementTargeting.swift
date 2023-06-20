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
        case autoTag
    }

    let accessibilityIdentifier: String?
    let tag: String?
    let appcuesID: String?
    let autoTag: String?

    init?(
        appcuesID: String?,
        accessibilityIdentifier: String?,
        accessibilityLabel: String?,
        tag: String?,
        autoTag: String? = nil
    ) {
        // must have at least one identifiable property to be a valid selector
        if appcuesID == nil && accessibilityIdentifier == nil && accessibilityLabel == nil && tag == nil && autoTag == nil {
            return nil
        }

        self.appcuesID = appcuesID
        self.accessibilityIdentifier = accessibilityIdentifier
        self.tag = tag
        self.autoTag = autoTag

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

        if autoTag != nil && autoTag == other.autoTag {
            weight += 5_000
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
        if let autoTag = autoTag, !autoTag.isEmpty {
            try container.encode(autoTag, forKey: .autoTag)
        }
    }

    func displayName(with type: String) -> String? {
        if let appcuesID = appcuesID {
            return appcuesID
        } else if let accessibilityIdentifier = accessibilityIdentifier {
            return accessibilityIdentifier
        } else if let autoTag = autoTag {
            return autoTag
        } else if let tag = tag {
            return "\(type) (tag \(tag))"
        } else if let accessibilityLabel = accessibilityLabel {
            return "\(type) (\(accessibilityLabel))"
        }

        return nil
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
            tag: properties["tag"],
            autoTag: properties["autoTag"]
        )
    }
}

internal extension UIView {
    private var displayType: String {
        return "\(type(of: self))"
    }

    private func getAppcuesSelector(autoTag: String? = nil) -> UIKitElementSelector? {
        return UIKitElementSelector(
            appcuesID: (self as? AppcuesTargetView)?.appcuesID,
            accessibilityIdentifier: accessibilityIdentifier,
            accessibilityLabel: accessibilityLabel,
            tag: tag != 0 ? "\(self.tag)" : nil,
            autoTag: autoTag
        )
    }

    func asViewElement() -> AppcuesViewElement? {
        return self.asViewElement(in: self.bounds, autoTag: nil)
    }

    private func asViewElement(in bounds: CGRect, autoTag: String?) -> AppcuesViewElement? {
        let absolutePosition = self.convert(self.bounds, to: nil)

        // discard views that are not visible in the screenshot image
        guard absolutePosition.intersects(bounds) else { return nil }

        var tabCount = 0

        let children: [AppcuesViewElement] = self.subviews.compactMap { subview -> AppcuesViewElement? in
            // discard hidden views and subviews within
            guard !subview.isHidden else { return nil }
            var childTabIndex: Int?
            if subview.displayType == "UITabBarButton" {
                tabCount += 1
                childTabIndex = tabCount - 1
            }
            let childAutoTag = getAutoTag(tabIndex: childTabIndex)
            return subview.asViewElement(in: bounds, autoTag: childAutoTag)
        }

        let selector = getAppcuesSelector(autoTag: autoTag)

        return AppcuesViewElement(
            x: absolutePosition.origin.x,
            y: absolutePosition.origin.y,
            width: absolutePosition.width,
            height: absolutePosition.height,
            type: displayType,
            selector: selector,
            children: children.isEmpty ? nil : children,
            displayName: selector?.displayName(with: displayType)
        )
    }

    // if/when any other auto tag capabilities are developed, can add logic here
    // to generate the selector string representation
    private func getAutoTag(tabIndex: Int?) -> String? {
        return tabIndex.flatMap { "tab[\($0)]" }
    }
}
