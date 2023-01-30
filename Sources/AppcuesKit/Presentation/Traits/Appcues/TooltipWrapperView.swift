//
//  TooltipWrapperView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-19.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class TooltipWrapperView: ExperienceWrapperView {

    private static let defaultMaxWidth: CGFloat = 400

    var preferredWidth: CGFloat?
    var preferredPosition: ContentPosition?
    /// A nil pointerSize means no pointer
    var pointerSize: CGSize?
    var distanceFromTarget: CGFloat = 0

    var targetRectangle: CGRect? {
        didSet {
            positionContentView()
        }
    }

    private var pointerInset: UIEdgeInsets = .zero {
        didSet {
            pointerInsetHandler?(pointerInset)
        }
    }
    var pointerInsetHandler: ((UIEdgeInsets) -> Void)?

    private var actualPosition: ContentPosition?
    private var offsetFromCenter: CGFloat = 0
    private var maxCornerRadius: CGFloat = 0

    private let maskLayer = CAShapeLayer()
    private let innerMaskLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()

    required init() {
        super.init()

        // Don't clip corners since they're applied by the mask
        contentWrapperView.clipsToBounds = false
        contentWrapperView.layer.mask = maskLayer
        contentWrapperView.layer.addSublayer(borderLayer)
        borderLayer.fillColor = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        positionContentView()

        // Ensure corner radius doesn't exceed 50% of either of the size dimensions
        let cornerRadius = min(
            maxCornerRadius,
            (contentWrapperView.bounds.height - pointerInset.top - pointerInset.bottom) / 2,
            (contentWrapperView.bounds.width - pointerInset.left - pointerInset.right) / 2
        )

        // Set tooltip shape for container, border, and shadow
        let outerTooltipPath = tooltipPath(in: contentWrapperView.bounds, cornerRadius: cornerRadius)
        maskLayer.path = outerTooltipPath
        borderLayer.path = outerTooltipPath
        shadowWrappingView.layer.shadowPath = outerTooltipPath

        // Set tooltip shape for content inside the border
        if let innerView = contentWrapperView.subviews.first {
            innerMaskLayer.path = tooltipPath(
                in: innerView.bounds,
                cornerRadius: cornerRadius - borderLayer.lineWidth / 2)
            innerView.layer.mask = innerMaskLayer
        }
    }

    override func positionContentView() {
        defer {
            contentWrapperView.frame = shadowWrappingView.bounds
            setPointerInset(position: actualPosition)
        }

        guard let targetRectangle = targetRectangle else {
            // Default to a bottom anchored sheet
            let defaultHeight: CGFloat = 300
            let contentWidth = bounds.width - layoutMargins.left - layoutMargins.right
            var contentHeight = max((preferredContentSize?.height ?? defaultHeight), 1)
            // Account for border size
            contentHeight += contentWrapperView.layoutMargins.top + contentWrapperView.layoutMargins.bottom
            shadowWrappingView.frame = CGRect(
                x: (bounds.width - contentWidth) / 2,
                y: bounds.height - contentHeight - safeAreaInsets.bottom,
                width: contentWidth,
                height: contentHeight)
            actualPosition = nil

            return
        }

        switch preferredPosition {
        case .none, .top, .bottom:
            shadowWrappingView.frame = verticalPosition(for: targetRectangle)
        case .leading, .trailing:
            shadowWrappingView.frame = horizontalPosition(for: targetRectangle)
        }
    }

    override func applyCornerRadius(_ cornerRadius: CGFloat?) {
        maxCornerRadius = cornerRadius ?? 0
    }

    override func applyBorder(color: UIColor?, width: CGFloat?) {
        guard let color = color, let width = width else { return }

        borderLayer.strokeColor = color.cgColor
        // Multiply by 2 because the stroke is drawn on the edge of the path. The outer half of the strike is trimmed by the mask,
        // so this is more efficient then calculating another path inset from the tooltip shape path specifically for the border.
        borderLayer.lineWidth = width * 2
        contentWrapperView.layoutMargins = UIEdgeInsets(top: width, left: width, bottom: width, right: width)
    }

    private func verticalPosition(for targetRectangle: CGRect) -> CGRect {
        let distance = distanceFromTarget

        let safeBounds = bounds.inset(by: safeAreaInsets)

        var targetFrame = CGRect(
            x: 0,
            y: 0,
            width: ceil(preferredWidth ?? preferredContentSize?.width ?? Self.defaultMaxWidth),
            height: ceil(preferredContentSize?.height ?? 1))

        // Account for border size
        targetFrame.size.height += contentWrapperView.layoutMargins.top + contentWrapperView.layoutMargins.bottom
        // Account for safe area space allocated to the pointer
        targetFrame.size.height += pointerSize?.height ?? 0
 
        // Cap width to not exceed screen width
        targetFrame.size.width = min(targetFrame.size.width, safeBounds.width - layoutMargins.left - layoutMargins.right)

        // Determine vertical positioning for targetFrame
        let spaceAbove = targetRectangle.minY - safeBounds.minY - distance
        let spaceBelow = safeBounds.maxY - targetRectangle.maxY - distance
        let excessSpaceAbove = spaceAbove - targetFrame.height
        let excessSpaceBelow = spaceBelow - targetFrame.height

        if preferredPosition == .top && excessSpaceAbove > 0 {
            // Position tooltip above the target rectangle
            targetFrame.origin.y = targetRectangle.minY - targetFrame.height - distance
            actualPosition = .top
        } else if preferredPosition == .bottom && excessSpaceBelow > 0 {
            // Position tooltip below the target rectangle
            targetFrame.origin.y = targetRectangle.maxY + distance
            actualPosition = .bottom
        } else {
            // TODO: Should this consider a switch to horizontal if there's not enough vertical space on either side?
            if excessSpaceAbove > excessSpaceBelow {
                // Position tooltip above the target rectangle
                if targetFrame.height <= spaceAbove {
                    targetFrame.origin.y = targetRectangle.minY - targetFrame.height - distance
                } else {
                    // Shrink height if too tall to fit
                    targetFrame.size.height = spaceAbove
                    targetFrame.origin.y = safeBounds.minY
                }
                actualPosition = .top
            } else {
                // Position tooltip below the target rectangle
                targetFrame.origin.y = targetRectangle.maxY + distance

                // Shrink height if too tall to fit
                if targetFrame.height > spaceBelow {
                    targetFrame.size.height = spaceBelow
                }
                actualPosition = .bottom
            }
        }

        // Determine horizontal positioning for targetFrame
        let preferredOriginX = targetRectangle.midX - targetFrame.width / 2
        if preferredOriginX < layoutMargins.left {
            // Must be within the left edge of the screen
            targetFrame.origin.x = layoutMargins.left
        } else if preferredOriginX + targetFrame.width > safeBounds.width - layoutMargins.right {
            // Must be within the right edge of the screen
            targetFrame.origin.x = safeBounds.width - targetFrame.width - layoutMargins.right
        } else {
            // Ideally be centered on the target rectangle
            targetFrame.origin.x = preferredOriginX
        }

        offsetFromCenter = preferredOriginX - targetFrame.origin.x

        return targetFrame
    }

    private func horizontalPosition(for targetRectangle: CGRect) -> CGRect {
        let distance = distanceFromTarget

        let safeBounds = bounds.inset(by: safeAreaInsets)

        var targetFrame = CGRect(
            x: 0,
            y: 0,
            width: ceil(preferredWidth ?? preferredContentSize?.width ?? Self.defaultMaxWidth),
            height: ceil(preferredContentSize?.height ?? 1))

        // Account for border size
        targetFrame.size.height += contentWrapperView.layoutMargins.top + contentWrapperView.layoutMargins.bottom
        // Account for safe area space allocated to the pointer
        targetFrame.size.width += pointerSize?.height ?? 0

        // Cap height to not exceed screen height
        targetFrame.size.height = min(targetFrame.size.height, safeBounds.height - layoutMargins.top - layoutMargins.bottom)

        // Determine horizontal positioning for targetFrame
        let spaceBefore = targetRectangle.minX - safeBounds.minX - distance
        let spaceAfter = safeBounds.maxX - targetRectangle.maxX - distance
        let excessSpaceBefore = spaceBefore - targetFrame.width
        let excessSpaceAfter = spaceAfter - targetFrame.width

        if preferredPosition == .leading && excessSpaceBefore > 0 {
            // Position tooltip before the target rectangle
            targetFrame.origin.x = targetRectangle.minX - targetFrame.width - distance
            actualPosition = .leading
        } else if preferredPosition == .trailing && excessSpaceAfter > 0 {
            // Position tooltip after the target rectangle
            targetFrame.origin.x = targetRectangle.maxX + distance
            actualPosition = .trailing
        } else {
            // TODO: Should this consider a switch to vertical if there's not enough vertical space on either side?
            if excessSpaceBefore > excessSpaceAfter {
                // Position tooltip before the target rectangle
                if targetFrame.width <= spaceBefore {
                    targetFrame.origin.x = targetRectangle.minX - targetFrame.width - distance
                } else {
                    // Shrink width if too wide to fit
                    targetFrame.size.width = spaceBefore
                    targetFrame.origin.x = safeBounds.minX
                }
                actualPosition = .leading
            } else {
                // Position tooltip after the target rectangle
                targetFrame.origin.x = targetRectangle.maxX + distance

                // Shrink width if too tall to fit
                if targetFrame.width > spaceAfter {
                    targetFrame.size.width = spaceAfter
                }
                actualPosition = .trailing
            }
        }

        // Determine vertical positioning for targetFrame
        let preferredOriginY = targetRectangle.midY - targetFrame.height / 2
        if preferredOriginY < layoutMargins.top {
            // Must be within the top edge of the screen
            targetFrame.origin.y = layoutMargins.top
        } else if preferredOriginY + targetFrame.height > safeBounds.height - layoutMargins.bottom {
            // Must be within the bottom edge of the screen
            targetFrame.origin.y = safeBounds.height - targetFrame.height - layoutMargins.bottom
        } else {
            // Ideally be centered on the target rectangle
            targetFrame.origin.y = preferredOriginY
        }

        offsetFromCenter = preferredOriginY - targetFrame.origin.y

        return targetFrame
    }

    private func setPointerInset(position: ContentPosition?) {
        switch position {
        case .none:
            pointerInset = .zero
        case .top:
            pointerInset = UIEdgeInsets(top: 0, left: 0, bottom: pointerSize?.height ?? 0, right: 0)
        case .bottom:
            pointerInset = UIEdgeInsets(top: pointerSize?.height ?? 0, left: 0, bottom: 0, right: 0)
        case .leading:
            pointerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: pointerSize?.height ?? 0)
        case .trailing:
            pointerInset = UIEdgeInsets(top: 0, left: pointerSize?.height ?? 0, bottom: 0, right: 0)
        }
    }

    private func tooltipPath(in bounds: CGRect, cornerRadius: CGFloat) -> CGPath {
        guard let pointerSize = pointerSize, let tooltipPosition = actualPosition else {
            // no pointer, so a simple roundedRect will do
            return UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        }

        let mainRect = bounds.inset(by: UIEdgeInsets(
            top: tooltipPosition == .bottom ? pointerSize.height : 0,
            left: tooltipPosition == .trailing ? pointerSize.height : 0,
            bottom: tooltipPosition == .top ? pointerSize.height : 0,
            right: tooltipPosition == .leading ? pointerSize.height : 0)
        )

        let triangleRect: CGRect

        // Clamp to ensure the triangle doesnt intersect with the corner radius
        switch tooltipPosition {
        case .top:
            // Bottom triangle
            triangleRect = CGRect(
                x: (mainRect.midX - pointerSize.width / 2 + offsetFromCenter)
                    .clamped(min: cornerRadius, max: mainRect.maxX - pointerSize.width - cornerRadius),
                y: mainRect.maxY,
                width: pointerSize.width,
                height: pointerSize.height)
        case .bottom:
            // Top triangle
            triangleRect = CGRect(
                x: (mainRect.midX - pointerSize.width / 2 + offsetFromCenter)
                    .clamped(min: cornerRadius, max: mainRect.maxX - pointerSize.width - cornerRadius),
                y: mainRect.minY - pointerSize.height,
                width: pointerSize.width,
                height: pointerSize.height)
        case .leading:
            // Trailing triangle
            triangleRect = CGRect(
                x: mainRect.maxX,
                y: (mainRect.midY - pointerSize.width / 2 + offsetFromCenter)
                    .clamped(min: cornerRadius, max: mainRect.maxY - pointerSize.width - cornerRadius),
                width: pointerSize.height,
                height: pointerSize.width)
        case .trailing:
            // Leading triangle
            triangleRect = CGRect(
                x: mainRect.minX - pointerSize.height,
                y: (mainRect.midY - pointerSize.width / 2 + offsetFromCenter)
                    .clamped(min: cornerRadius, max: mainRect.maxY - pointerSize.width - cornerRadius),
                width: pointerSize.height,
                height: pointerSize.width)
        }

        let topLeft = CGPoint(x: mainRect.minX + cornerRadius, y: mainRect.minY + cornerRadius)
        let topRight = CGPoint(x: mainRect.maxX - cornerRadius, y: mainRect.minY + cornerRadius)
        let bottomLeft = CGPoint(x: mainRect.minX + cornerRadius, y: mainRect.maxY - cornerRadius)
        let bottomRight = CGPoint(x: mainRect.maxX - cornerRadius, y: mainRect.maxY - cornerRadius)

        // Draw the path clockwise from top left
        let tooltipPath = UIBezierPath()

        tooltipPath.addArc(withCenter: topLeft, radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)

        // Top triangle
        if case .bottom = tooltipPosition {
            tooltipPath.addLine(to: CGPoint(x: triangleRect.minX, y: triangleRect.maxY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.midX, y: triangleRect.minY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.maxX, y: triangleRect.maxY))
        }

        tooltipPath.addArc(withCenter: topRight, radius: cornerRadius, startAngle: -.pi / 2, endAngle: 0, clockwise: true)

        // Trailing triangle
        if case .leading = tooltipPosition {
            tooltipPath.addLine(to: CGPoint(x: triangleRect.minX, y: triangleRect.minY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.maxX, y: triangleRect.midY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.minX, y: triangleRect.maxY))
        }

        tooltipPath.addArc(withCenter: bottomRight, radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)

        // Bottom triangle
        if case .top = tooltipPosition {
            tooltipPath.addLine(to: CGPoint(x: triangleRect.maxX, y: triangleRect.minY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.midX, y: triangleRect.maxY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.minX, y: triangleRect.minY))
        }

        tooltipPath.addArc(withCenter: bottomLeft, radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)

        // Leading triangle
        if case .trailing = tooltipPosition {
            tooltipPath.addLine(to: CGPoint(x: triangleRect.maxX, y: triangleRect.maxY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.minX, y: triangleRect.midY))
            tooltipPath.addLine(to: CGPoint(x: triangleRect.maxX, y: triangleRect.minY))
        }

        tooltipPath.close()

        return tooltipPath.cgPath
    }

}

enum ContentPosition: String, Decodable {
    case top
    case bottom
    case leading
    case trailing
}

extension Comparable {
    // Not using a ClosedRange<Self> because of the risk of a crash, "Range requires lowerBound <= upperBound"
    func clamped(min lowerBound: Self, max upperBound: Self) -> Self {
        return min(max(self, lowerBound), upperBound)
    }
}
