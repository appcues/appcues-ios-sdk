//
//  UIKitElementTargeting.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/20/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit
import WebKit

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
        // redefine selector prop values, coercing and empty strings to nil first
        // an empty string is not valid for a selector property
        let appcuesID = appcuesID.emptyToNil()
        let accessibilityIdentifier = accessibilityIdentifier.emptyToNil()
        let accessibilityLabel = accessibilityLabel.emptyToNil()
        let tag = tag.emptyToNil()
        let autoTag = autoTag.emptyToNil()

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

    func captureLayout() async -> AppcuesViewElement? {
        let captureWindow = await UIApplication.shared.appWindow
        return await (window ?? captureWindow)?.asViewElement()
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

    func asViewElement() async -> AppcuesViewElement? {
        return await self.asViewElement(in: self.bounds, safeAreaInsets: self.safeAreaInsets, autoTag: nil)
    }

    private func asViewElement(in bounds: CGRect, safeAreaInsets: UIEdgeInsets, autoTag: String?) async -> AppcuesViewElement? {
        let absolutePosition = self.convert(self.bounds, to: nil)

        // discard views that are not visible in the screenshot image
        guard absolutePosition.intersects(bounds) else { return nil }

        let childInsets = UIEdgeInsets(
            top: max(safeAreaInsets.top, self.safeAreaInsets.top),
            left: max(safeAreaInsets.left, self.safeAreaInsets.left),
            bottom: max(safeAreaInsets.bottom, self.safeAreaInsets.bottom),
            right: max(safeAreaInsets.right, self.safeAreaInsets.right)
        )

        var tabCount = 0

        let children: [AppcuesViewElement]

        if let webView = self as? WKWebView {
            children = await webViewChildren(webView, positionAdjustment: absolutePosition.inset(by: childInsets))
        } else {
            children = await self.subviews.asyncCompactMap { subview -> AppcuesViewElement? in
                // discard hidden views and subviews within
                guard !subview.isHidden else { return nil }
                var childTabIndex: Int?
                if subview.displayType == "UITabBarButton" {
                    tabCount += 1
                    childTabIndex = tabCount - 1
                }
                let childAutoTag = getAutoTag(tabIndex: childTabIndex)
                return await subview.asViewElement(in: bounds, safeAreaInsets: childInsets, autoTag: childAutoTag)
            }
        }

        // find the rect of the visible area of the view within the safe area
        let safeBounds = bounds.inset(by: safeAreaInsets)
        let visibleRect = safeBounds.intersection(absolutePosition)

        // if there is no visible rect, fall back to the absolute position, but we will
        // not generate any selector for non-visible item below. Do not skip the item entirely
        // since it could have children that are within the visible range (out of bounds of parent)
        let locationRect = visibleRect.isNull ? absolutePosition : visibleRect

        // only create a selector for elements that have at least the center point
        // visible in the current screen bounds, inset by any safe area adjustments
        let centerPointVisible = safeBounds.contains(CGPoint(x: absolutePosition.midX, y: absolutePosition.midY))
        let selector = centerPointVisible ? getAppcuesSelector(autoTag: autoTag) : nil

        return AppcuesViewElement(
            x: locationRect.origin.x,
            y: locationRect.origin.y,
            width: locationRect.width,
            height: locationRect.height,
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

    private func webViewChildren(_ webView: WKWebView, positionAdjustment: CGRect) async -> [AppcuesViewElement] {
        let script = """
        [...document.querySelectorAll('button')].map (el => {
            const { x, y, width, height } = el.getBoundingClientRect();
            return {
                x,
                y,
                width,
                height,
                selector: `html-${el.id}`,
            }
        });
        """

        let response = try? await webView.evaluateJavaScript(script)

        guard let objects = response as? [Dictionary<String, Any>] else { return [] }

        return objects.map { element in
            AppcuesViewElement(
                x: positionAdjustment.minX + (element["x"] as? CGFloat ?? 0),
                y: positionAdjustment.minY + (element["y"] as? CGFloat ?? 0),
                width: element["width"] as? CGFloat ?? 0,
                height: element["height"] as? CGFloat ?? 0,
                type: "htmlNode",
                selector: UIKitElementSelector(
                    appcuesID: element["selector"] as? String,
                    accessibilityIdentifier: nil,
                    accessibilityLabel: nil,
                    tag: nil
                ),
                children: nil
            )
        }
    }
}

private extension Optional where Wrapped == String {
    func emptyToNil() -> String? {
        self.flatMap { $0.isEmpty ? nil : $0 }
    }
}

public extension Sequence {
    /// Transform the sequence into an array of new values using
    /// an async closure that returns optional values. Only the
    /// non-`nil` return values will be included in the new array.
    ///
    /// The closure calls will be performed in order, by waiting for
    /// each call to complete before proceeding with the next one. If
    /// any of the closure calls throw an error, then the iteration
    /// will be terminated and the error rethrown.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence,
    ///   except for the values that were transformed into `nil`.
    /// - throws: Rethrows any error thrown by the passed closure.
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            guard let value = try await transform(element) else {
                continue
            }

            values.append(value)
        }

        return values
    }
}
