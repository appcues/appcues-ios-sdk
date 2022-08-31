//
//  UIView+Capture.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

extension UIView {

    var appcuesSelector: ElementSelector {
        if let accessibilityID = self.accessibilityIdentifier {
            return .accessibilityID(accessibilityID)
        } else if tag != 0 {
            return .tag(tag)
        } else {
            return .unknown
        }
    }

    func viewMatchingSelector(_ selector: ElementSelector) -> UIView? {
        if selector != .unknown && self.appcuesSelector == selector { return self }
        for subview in self.subviews {
            if let matchingView = subview.viewMatchingSelector(selector) { return matchingView }
        }
        return nil
    }

    func capture() -> Capture? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 1)
        defer {
            UIGraphicsEndImageContext()
        }

        layer.render(in: UIGraphicsGetCurrentContext()!)
        guard let imageData = UIGraphicsGetImageFromCurrentImageContext()?.jpegData(compressionQuality: 0.5) else { return nil }

        return Capture(
            imageData: imageData,
            hierarchy: self.asNode()
        )
    }

    private func asNode() -> Capture.Node? {
        let absolutePosition = self.convert(self.bounds, to: nil)

        var children: [Capture.Node] = []
        self.subviews.forEach {
            if !$0.isHidden, let node = $0.asNode() {
                children.append(node)
            }
        }

        return Capture.Node(
            type: "\(type(of: self))",
            selector: appcuesSelector,
            absolutePosition: Capture.Position(absolutePosition),
            children: children
        )
    }
}
