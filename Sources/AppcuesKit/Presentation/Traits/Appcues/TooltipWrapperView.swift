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
    case left
    case right
}

@available(iOS 13.0, *)
internal class TooltipWrapperView: ExperienceWrapperView {

    private static let defaultMaxWidth: CGFloat = 400
    private static let minContentHeight: CGFloat = 46

    var preferredWidth: CGFloat?

    /// If we're using the preferredContentSize, we need to add the border width that's set in the layoutMargins to avoid sizing
    /// targetFrame.width to just *less* than the preferred width and creating a loop that eventually sizes the frame width to 0.
    private var preferredContentWidth: CGFloat? {
        guard let width = preferredContentSize?.width else { return nil }
        return width + contentWrapperView.layoutMargins.left + contentWrapperView.layoutMargins.right
    }

    var preferredPosition: ContentPosition?
    /// A nil pointerSize means no pointer
    var pointerSize: CGSize?
    var pointerCornerRadius: CGFloat = 0
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
    private let borderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 0
        return layer
    }()

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
        let boxCornerRadius = min(
            maxCornerRadius,
            (contentWrapperView.bounds.height - pointerInset.top - pointerInset.bottom) / 2,
            (contentWrapperView.bounds.width - pointerInset.left - pointerInset.right) / 2
        )

        // Set tooltip shape for container, border, and shadow
        let outerTooltipPath = tooltipPath(in: contentWrapperView.bounds, boxCornerRadius: boxCornerRadius)
        maskLayer.path = outerTooltipPath
        borderLayer.path = outerTooltipPath
        shadowWrappingView.layer.shadowPath = outerTooltipPath

        // Set tooltip shape for content inside the border
        if let innerView = contentWrapperView.subviews.first {
            let innerBounds = CGRect(
                x: 0,
                y: 0,
                // the visible lineWidth is /2, but then we need to *2 for each side
                width: contentWrapperView.bounds.width - borderLayer.lineWidth,
                height: contentWrapperView.bounds.height - borderLayer.lineWidth
            )
            innerMaskLayer.path = tooltipPath(
                in: innerBounds,
                boxCornerRadius: boxCornerRadius - borderLayer.lineWidth / 2
            )
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
            let safeBounds = bounds.inset(by: safeAreaInsets)
            let contentWidth = bounds.width - layoutMargins.left - layoutMargins.right
            var contentHeight = max((preferredContentSize?.height ?? defaultHeight), 1)
            // Account for border size
            contentHeight += contentWrapperView.layoutMargins.top + contentWrapperView.layoutMargins.bottom
            contentHeight = min(contentHeight, safeBounds.height)
            shadowWrappingView.frame = CGRect(
                x: (bounds.width - contentWidth) / 2,
                y: safeBounds.maxY - contentHeight,
                width: contentWidth,
                height: contentHeight
            )
            actualPosition = nil

            return
        }

        shadowWrappingView.frame = tooltipPosition(for: targetRectangle)
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

    // swiftlint:disable:next function_body_length
    private func tooltipPosition(for targetRectangle: CGRect) -> CGRect {
        let distance = distanceFromTarget

        let safeBounds = bounds.inset(by: layoutMargins)

        var targetFrame = CGRect(
            x: 0,
            y: 0,
            width: ceil(preferredWidth ?? preferredContentWidth ?? Self.defaultMaxWidth),
            height: ceil(max((preferredContentSize?.height ?? 0), Self.minContentHeight))
        )

        // Account for border size and safe area space allocated to the pointer.
        let additionalBorderHeight = contentWrapperView.layoutMargins.top + contentWrapperView.layoutMargins.bottom
        let additionalPointerLength = pointerSize?.height ?? 0
        // We only want to add additionalPointerHeight once we know the pointer is top/bottom.
        targetFrame.size.height += additionalBorderHeight

        // Cap size to not exceed safe screen size.
        targetFrame.size.width = min(targetFrame.size.width, safeBounds.width)
        targetFrame.size.height = min(targetFrame.size.height, safeBounds.height)

        // Determine available space for targetFrame.
        let safeSpaceAbove = (targetRectangle.minY - distance).clamped(to: safeBounds.minY...safeBounds.maxY) - safeBounds.minY
        let safeSpaceBelow = safeBounds.maxY - (targetRectangle.maxY + distance).clamped(to: safeBounds.minY...safeBounds.maxY)
        let safeSpaceBefore = (targetRectangle.minX - distance).clamped(to: safeBounds.minX...safeBounds.maxX) - safeBounds.minX
        let safeSpaceAfter = safeBounds.maxX - (targetRectangle.maxX + distance).clamped(to: safeBounds.minX...safeBounds.maxX)

        let excessSpaceAbove = safeSpaceAbove - (targetFrame.height + additionalPointerLength)
        let excessSpaceBelow = safeSpaceBelow - (targetFrame.height + additionalPointerLength)
        let excessSpaceBefore = safeSpaceBefore - (targetFrame.width + additionalPointerLength)
        let excessSpaceAfter = safeSpaceAfter - (targetFrame.width + additionalPointerLength)

        let verticalSpaceIsAvailable = excessSpaceAbove > 0 || excessSpaceBelow > 0
        let horizontalSpaceIsAvailable = excessSpaceBefore > 0 || excessSpaceAfter > 0

        if preferredPosition == .top && excessSpaceAbove > 0 {
            return tooltipFrame(position: .top)
        } else if preferredPosition == .bottom && excessSpaceBelow > 0 {
            return tooltipFrame(position: .bottom)
        } else if preferredPosition == .left && excessSpaceBefore > 0 {
            return tooltipFrame(position: .left)
        } else if preferredPosition == .right && excessSpaceAfter > 0 {
            return tooltipFrame(position: .right)
        } else if verticalSpaceIsAvailable {
            return tooltipFrame(position: excessSpaceAbove > excessSpaceBelow ? .top : .bottom)
        } else if horizontalSpaceIsAvailable {
            return tooltipFrame(position: excessSpaceBefore > excessSpaceAfter ? .left : .right)
        } else {
            // Doesn't fit anywhere so pick the top/bottom side that has the most space.
            // Allowing left/right here would mean the width gets compressed and that opens a can of worms.
            return tooltipFrame(position: excessSpaceAbove > excessSpaceBelow ? .top : .bottom)
        }

        func tooltipFrame(position: ContentPosition) -> CGRect {
            let minContentSize = Self.minContentHeight + additionalBorderHeight + additionalPointerLength
            switch position {
            case .top:
                targetFrame.size.height += additionalPointerLength
                // Position tooltip above the target rectangle and within the safe area.
                if targetFrame.height <= safeSpaceAbove {
                    // `min` in case `targetRectangle` is outside the bottom edge of the safe area.
                    targetFrame.origin.y = min(targetRectangle.minY - distance, safeBounds.maxY) - targetFrame.height
                } else {
                    // Shrink height if too tall to fit.
                    targetFrame.size.height = max(safeSpaceAbove, minContentSize)
                    targetFrame.origin.y = safeBounds.minY
                }
            case .bottom:
                targetFrame.size.height += additionalPointerLength
                // Position tooltip below the target rectangle and within the safe area.
                if targetFrame.height <= safeSpaceBelow {
                    // `max` in case `targetRectangle` is outside the top edge of the safe area.
                    targetFrame.origin.y = max(targetRectangle.maxY + distance, safeBounds.minY)
                } else {
                    // Shrink height if too tall to fit
                    targetFrame.size.height = max(safeSpaceBelow, minContentSize)
                    targetFrame.origin.y = safeBounds.maxY - targetFrame.size.height
                }
            case .left:
                targetFrame.size.width += additionalPointerLength
                // Position tooltip before the target rectangle and within the safe area.
                if targetFrame.width <= safeSpaceBefore {
                    // `min` in case `targetRectangle` is outside the trailing edge of the safe area.
                    targetFrame.origin.x = min(targetRectangle.minX - distance, safeBounds.maxX) - targetFrame.width
                } else {
                    // Shrink width if too wide to fit.
                    targetFrame.size.width = max(safeSpaceBefore, minContentSize)
                    targetFrame.origin.x = safeBounds.minX
                }
            case .right:
                targetFrame.size.width += additionalPointerLength
                // Position tooltip after the target rectangle and within the safe area.
                if targetFrame.width <= safeSpaceAfter {
                    // `max` in case `targetRectangle` is outside the leading edge of the safe area.
                    targetFrame.origin.x = max(targetRectangle.maxX + distance, safeBounds.minX)
                } else {
                    // Shrink width if too wide to fit.
                    targetFrame.size.width = max(safeSpaceAfter, minContentSize)
                    targetFrame.origin.x = safeBounds.maxX - targetFrame.size.width
                }
            }

            // Determine positioning orthogonal to the preferred axis.
            switch position {
            case .top, .bottom:
                let preferredOriginX = targetRectangle.midX - targetFrame.width / 2

                // Ideally be centered on the target rectangle, but clamp to the safe edges.
                targetFrame.origin.x = preferredOriginX.clamped(to: safeBounds.minX...safeBounds.maxX - targetFrame.width)

                offsetFromCenter = preferredOriginX - targetFrame.origin.x
            case .left, .right:
                let preferredOriginY = targetRectangle.midY - targetFrame.height / 2

                // Ideally be centered on the target rectangle, but clamp to the safe edges.
                targetFrame.origin.y = preferredOriginY.clamped(to: safeBounds.minY...safeBounds.maxY - targetFrame.height)

                offsetFromCenter = preferredOriginY - targetFrame.origin.y
            }

            actualPosition = position
            return targetFrame
        }
    }

    private func setPointerInset(position: ContentPosition?) {
        switch position {
        case .none:
            pointerInset = .zero
        case .top:
            pointerInset = UIEdgeInsets(top: 0, left: 0, bottom: pointerSize?.height ?? 0, right: 0)
        case .bottom:
            pointerInset = UIEdgeInsets(top: pointerSize?.height ?? 0, left: 0, bottom: 0, right: 0)
        case .left:
            pointerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: pointerSize?.height ?? 0)
        case .right:
            pointerInset = UIEdgeInsets(top: 0, left: pointerSize?.height ?? 0, bottom: 0, right: 0)
        }
    }

    private func tooltipPath(in bounds: CGRect, boxCornerRadius: CGFloat) -> CGPath {
        guard let pointerSize = pointerSize, let tooltipPosition = actualPosition else {
            // no pointer, so a simple roundedRect will do
            return UIBezierPath(roundedRect: bounds, cornerRadius: boxCornerRadius).cgPath
        }

        let mainRect = bounds.inset(by: UIEdgeInsets(
            top: tooltipPosition == .bottom ? pointerSize.height : 0,
            left: tooltipPosition == .right ? pointerSize.height : 0,
            bottom: tooltipPosition == .top ? pointerSize.height : 0,
            right: tooltipPosition == .left ? pointerSize.height : 0
        ))

        let pointerEdge: Pointer.Edge
        let pointerSideLength: CGFloat
        switch tooltipPosition {
        case .top:
            pointerEdge = .bottom
            pointerSideLength = mainRect.width
        case .bottom:
            pointerEdge = .top
            pointerSideLength = mainRect.width
        case .left:
            pointerEdge = .right
            pointerSideLength = mainRect.height
        case .right:
            pointerEdge = .left
            pointerSideLength = mainRect.height
        }

        let constrainedPointerSize = CGSize(
            width: min(pointerSize.width, pointerSideLength - boxCornerRadius * 2),
            height: pointerSize.height
        )

        let constrainedPointerCornerRadius = min(pointerCornerRadius, constrainedPointerSize.maxPointerCornerRadius)

        let pointer = Pointer(
            edge: pointerEdge,
            size: constrainedPointerSize,
            cornerRadius: constrainedPointerCornerRadius,
            offset: offsetFromCenter
        )
        return CGPath.tooltip(around: mainRect, boxCornerRadius: boxCornerRadius, pointer: pointer)
    }

}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
