//
//  UIKitElementTargeting.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/20/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

// UIKit selector implementation that uses accessibilityIdentifier,
// accessibiltyLabel, and tag data from the underlying UIView to identify elements.
internal class UIKitElementSelector: AppcuesElementSelector {

    let accessibilityIdentifier: String?
    let accessiblityLabel: String?
    let tag: String?

    init?(accessibilityIdentifier: String?, accessiblityLabel: String?, tag: String?) {
        // must have at least one identifiable property to be a valid selector
        if accessibilityIdentifier == nil && accessiblityLabel == nil && tag == nil {
            return nil
        }

        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessiblityLabel = accessiblityLabel
        self.tag = tag

        super.init()
    }

    override func evaluateMatch(for target: AppcuesElementSelector) -> Int {
        guard let other = target as? UIKitElementSelector else {
            return 0
        }

        // weight the selector property matches by how distinct they are considered
        var weight = 0

        if accessibilityIdentifier != nil && accessibilityIdentifier == other.accessibilityIdentifier {
            weight += 10_000
        }

        if tag != nil && tag == other.tag {
            weight += 1_000
        }

        if accessiblityLabel != nil && accessiblityLabel == other.accessiblityLabel {
            weight += 100
        }

        return weight
    }
}

// UIKit implementation of element targeting that captures the UIView hierarchy for the current UIWindow,
// and identifies applicable views with a UIKitElementSelector.
@available(iOS 13.0, *)
internal class UIKitElementTargeting: AppcuesElementTargeting {
    func captureLayout() -> AppcuesViewElement? {
        return UIApplication.shared.windows.first { !$0.isAppcuesWindow }?.captureLayout()
    }

    func inflateSelector(from properties: [String: String]) -> AppcuesElementSelector? {
        return UIKitElementSelector(
            accessibilityIdentifier: properties["accessibilityIdentifier"],
            accessiblityLabel: properties["accessiblityLabel"],
            tag: properties["tag"]
        )
    }
}
