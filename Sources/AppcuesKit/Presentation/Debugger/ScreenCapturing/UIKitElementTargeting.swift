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

    @MainActor
    func captureLayout() async -> AppcuesViewElement? {
        let captureWindow = window ?? UIApplication.shared.mainAppWindow
        return await captureWindow?.asViewElement()
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

@available(iOS 13.0, *)
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
            // Ionic apps seem to specifically ignore the safe area
            let adjustment: CGPoint = webView.scrollView.contentInsetAdjustmentBehavior == .never
            ? .zero
            : absolutePosition.inset(by: childInsets).origin
            children = await webView.children(positionAdjustment: adjustment)
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
}

@available(iOS 13.0, *)
private extension WKWebView {
    func children(positionAdjustment: CGPoint) async -> [AppcuesViewElement] {
        let script = """
        [...document.querySelectorAll('[id], [data-appcues-id]')].reduce((result, el) => {
            const { x, y, width, height } = el.getBoundingClientRect();
            const tag = el.id ? `#${el.id}` : null;
            const appcuesID = el.getAttribute('data-appcues-id')
            if (height !== 0 && width !== 0) {
                result.push({
                    x,
                    y,
                    width,
                    height,
                    tag,
                    appcuesID
                });
            }
            return result;
        }, []);
        """

        let response = try? await self.evaluateJavaScript(script)

        guard let objects = response as? [Dictionary<String, Any>] else { return [] }

        return objects.compactMap { element in
            guard let x = element["x"] as? CGFloat,
                  let y = element["y"] as? CGFloat,
                  let width = element["width"] as? CGFloat,
                  let height = element["height"] as? CGFloat
            else {
                return nil
            }

            let elementFrame = CGRect(x: x, y: y, width: width, height: height)
            guard self.bounds.contains(CGPoint(x: elementFrame.midX, y: elementFrame.midY)) else {
                return nil
            }

            let appcuesID = element["appcuesID"] as? String
            let tag = element["tag"] as? String

            return AppcuesViewElement(
                x: positionAdjustment.x + x,
                y: positionAdjustment.y + y,
                width: width,
                height: height,
                type: "HTMLNode",
                selector: UIKitElementSelector(
                    appcuesID: appcuesID,
                    accessibilityIdentifier: nil,
                    accessibilityLabel: nil,
                    tag: tag
                ),
                children: nil,
                displayName: appcuesID ?? tag
            )
        }
    }
}

private extension Optional where Wrapped == String {
    func emptyToNil() -> String? {
        self.flatMap { $0.isEmpty ? nil : $0 }
    }
}

@available(iOS 13.0, *)
internal extension Sequence {
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
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
