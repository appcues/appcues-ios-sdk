//
//  UnreadBadgeView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-04.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

internal class UnreadBadgeView: UILabel {

    var isDisabled = false

    var count: Int = 0 {
        didSet {
            isHidden = isDisabled || count < 1
            text = "\(count)"
            sizeToFit()
        }
    }

    var badgeColor = UIColor.red {
        didSet { setNeedsDisplay() }
    }

    var insets = CGSize(width: 5, height: 2) {
        didSet { invalidateIntrinsicContentSize() }
    }

    /// A value of `-1`  represents an automatic radius of 50%
    var radius: CGFloat = -1 {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        textAlignment = .center
        textColor = .white
        font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Add custom insets around the text
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let rect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)

        let rectWithDefaultInsets = rect.insetBy(dx: -insets.width, dy: -insets.height)

        // If width is less than height adjust the width insets to make it look round
        if rectWithDefaultInsets.width < rectWithDefaultInsets.height {
            insets.width = (rectWithDefaultInsets.height - rect.width) / 2
        }
        let result = rect.insetBy(dx: -insets.width, dy: -insets.height)

        return result
    }

    // Draws the label with insets
    override func drawText(in rect: CGRect) {
        if radius >= 0 {
            layer.cornerRadius = radius
        } else {
            // Use fully rounded corner if radius is not specified
            layer.cornerRadius = rect.height / 2
        }

        let textInsets = UIEdgeInsets(
            top: insets.height,
            left: insets.width,
            bottom: insets.height,
            right: insets.width)

        let rectWithoutInsets = rect.inset(by: textInsets)

        super.drawText(in: rectWithoutInsets)
    }

    override func draw(_ rect: CGRect) {
        let actualCornerRadius = radius >= 0 ? radius : rect.height / 2
        let path = UIBezierPath(roundedRect: rect, cornerRadius: actualCornerRadius)
        badgeColor.setFill()
        path.fill()

        super.draw(rect)
    }

}
