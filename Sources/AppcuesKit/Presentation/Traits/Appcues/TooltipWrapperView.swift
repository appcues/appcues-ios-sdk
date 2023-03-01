//
//  TooltipWrapperView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-19.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal enum ContentPosition: String, Decodable {
    case top
    case bottom
    case leading
    case trailing
}

@available(iOS 13.0, *)
internal class TooltipWrapperView: ExperienceWrapperView {

    private static let defaultMaxWidth: CGFloat = 400
    private static let minContentHeight: CGFloat = 46

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

        let safeBounds = bounds.inset(by: layoutMargins)

        var targetFrame = CGRect(
            x: 0,
            y: 0,
            width: ceil(preferredWidth ?? preferredContentSize?.width ?? Self.defaultMaxWidth),
            height: ceil(preferredContentSize?.height ?? 1))

        // Account for border size and safe area space allocated to the pointer
        let nonContentHeight = contentWrapperView.layoutMargins.top + contentWrapperView.layoutMargins.bottom + (pointerSize?.height ?? 0)
        targetFrame.size.height += nonContentHeight

        // Cap width to not exceed screen width
        targetFrame.size.width = min(targetFrame.size.width, safeBounds.width)

        // Determine vertical positioning for targetFrame
        let safeSpaceAbove = (targetRectangle.minY - distance).clamped(to: safeBounds.minY...safeBounds.maxY) - safeBounds.minY
        let safeSpaceBelow = safeBounds.maxY - (targetRectangle.maxY + distance).clamped(to: safeBounds.minY...safeBounds.maxY)
        let excessSpaceAbove = safeSpaceAbove - targetFrame.height
        let excessSpaceBelow = safeSpaceBelow - targetFrame.height

        if preferredPosition == .top && excessSpaceAbove > 0 {
            // Position tooltip above the target rectangle and within the safe area
            targetFrame.origin.y = min(targetRectangle.minY - distance, safeBounds.maxY) - targetFrame.height
            actualPosition = .top
        } else if preferredPosition == .bottom && excessSpaceBelow > 0 {
            // Position tooltip below the target rectangle and within the safe area
            targetFrame.origin.y = max(targetRectangle.maxY + distance, safeBounds.minY)
            actualPosition = .bottom
        } else {
            // TODO: Should this consider a switch to horizontal if there's not enough vertical space on either side?
            if excessSpaceAbove > excessSpaceBelow {
                // Position tooltip above the target rectangle
                if targetFrame.height <= safeSpaceAbove {
                    targetFrame.origin.y = min(targetRectangle.minY, safeBounds.maxY) - distance - targetFrame.height
                } else {
                    // Shrink height if too tall to fit
                    targetFrame.size.height = max(Self.minContentHeight + nonContentHeight, safeSpaceAbove)
                    targetFrame.origin.y = safeBounds.minY
                }
                actualPosition = .top
            } else {
                // Position tooltip below the target rectangle and within the safe area
                if targetFrame.height <= safeSpaceBelow {
                    targetFrame.origin.y = max(targetRectangle.maxY + distance, safeBounds.minY)
                } else {
                    // Shrink height if too tall to fit
                    targetFrame.size.height = max(Self.minContentHeight + nonContentHeight, safeSpaceBelow)
                    targetFrame.origin.y = safeBounds.maxY - targetFrame.size.height
                }
                actualPosition = .bottom
            }
        }

        // Determine horizontal positioning for targetFrame
        let preferredOriginX = targetRectangle.midX - targetFrame.width / 2

        // Ideally be centered on the target rectangle
        targetFrame.origin.x = preferredOriginX

        if targetFrame.minX < safeBounds.minX {
            // Must be within the left edge of the screen
            targetFrame.origin.x = safeBounds.minX
        } else if targetFrame.maxX > safeBounds.maxX {
            // Must be within the right edge of the screen
            targetFrame.origin.x = safeBounds.maxX - targetFrame.width
        }

        offsetFromCenter = preferredOriginX - targetFrame.origin.x

        return targetFrame
    }

    private func horizontalPosition(for targetRectangle: CGRect) -> CGRect {
        let distance = distanceFromTarget

        let safeBounds = bounds.inset(by: layoutMargins)

        var targetFrame = CGRect(
            x: 0,
            y: 0,
            width: ceil(preferredWidth ?? preferredContentSize?.width ?? Self.defaultMaxWidth),
            height: ceil(preferredContentSize?.height ?? 1))

        // Account for border size and safe area space allocated to the pointer
        let nonContentHeight = contentWrapperView.layoutMargins.top + contentWrapperView.layoutMargins.bottom + (pointerSize?.height ?? 0)
        targetFrame.size.height += nonContentHeight

        // Cap height to not exceed screen height
        targetFrame.size.height = min(targetFrame.size.height, safeBounds.height)

        // Determine horizontal positioning for targetFrame
        let safeSpaceBefore = (targetRectangle.minX - distance).clamped(to: safeBounds.minX...safeBounds.maxX) - safeBounds.minX
        let safeSpaceAfter = safeBounds.maxX - (targetRectangle.maxX + distance).clamped(to: safeBounds.minX...safeBounds.maxX)
        let excessSpaceBefore = safeSpaceBefore - targetFrame.width
        let excessSpaceAfter = safeSpaceAfter - targetFrame.width

        if preferredPosition == .leading && excessSpaceBefore > 0 {
            // Position tooltip before the target rectangle and within the safe area
            targetFrame.origin.x = min(targetRectangle.minX - distance, safeBounds.maxX) - targetFrame.width
            actualPosition = .leading
        } else if preferredPosition == .trailing && excessSpaceAfter > 0 {
            // Position tooltip after the target rectangle and within the safe area
            targetFrame.origin.x = max(targetRectangle.maxX + distance, safeBounds.minX)
            actualPosition = .trailing
        } else {
            // TODO: Should this consider a switch to vertical if there's not enough vertical space on either side?
            if excessSpaceBefore > excessSpaceAfter {
                // Position tooltip before the target rectangle
                if targetFrame.width <= safeSpaceBefore {
                    targetFrame.origin.x = targetRectangle.minX - distance - targetFrame.width
                } else {
                    // Shrink width if too wide to fit
                    targetFrame.size.width = safeSpaceBefore
                    targetFrame.origin.x = safeBounds.minX
                }
                actualPosition = .leading
            } else {
                // Position tooltip after the target rectangle and within the safe area
                targetFrame.origin.x = max(targetRectangle.maxX + distance, safeBounds.minX)

                // Shrink width if too tall to fit
                if targetFrame.width > safeSpaceAfter {
                    targetFrame.size.width = safeSpaceAfter
                }
                actualPosition = .trailing
            }
        }

        // Determine vertical positioning for targetFrame
        let preferredOriginY = targetRectangle.midY - targetFrame.height / 2

        // Ideally be centered on the target rectangle
        targetFrame.origin.y = preferredOriginY

        if targetFrame.minY < safeBounds.minY {
            // Must be within the top edge of the screen
            targetFrame.origin.y = safeBounds.minY
        } else if targetFrame.maxY > safeBounds.maxY {
            // Must be within the bottom edge of the screen
            targetFrame.origin.y = safeBounds.maxY - targetFrame.height
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

        let pointerEdge: Pointer.Edge
        let pointerSideLength: CGFloat
        switch tooltipPosition {
        case .top:
            pointerEdge = .bottom
            pointerSideLength = mainRect.width
        case .bottom:
            pointerEdge = .top
            pointerSideLength = mainRect.width
        case .leading:
            pointerEdge = .trailing
            pointerSideLength = mainRect.height
        case .trailing:
            pointerEdge = .leading
            pointerSideLength = mainRect.height
        }

        let constrainedPointerSize = CGSize(
            width: min(pointerSize.width, pointerSideLength - cornerRadius * 2),
            height: pointerSize.height
        )

        let pointer = Pointer(edge: pointerEdge, size: constrainedPointerSize, offset: offsetFromCenter)
        let tooltipPath = UIBezierPath(tooltipAround: mainRect, cornerRadius: cornerRadius, pointer: pointer)

        return tooltipPath.cgPath
    }

}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
