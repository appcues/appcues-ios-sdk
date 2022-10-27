//
//  View+CornerRadius.swift
//  AppcuesKit
//
//  Created by Matt on 2022-10-27.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct VariableRoundedCorner: Shape {
    let topLeft: CGFloat
    let topRight: CGFloat
    let bottomRight: CGFloat
    let bottomLeft: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()

        // topLeft
        let tlRadius = min(topLeft, rect.width / 2, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + tlRadius))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + tlRadius, y: rect.minY + tlRadius),
            radius: tlRadius,
            startAngle: .pi,
            endAngle: 3 * .pi / 2,
            clockwise: true)
        path.addLine(to: CGPoint(x: rect.minX + tlRadius, y: rect.minY))

        // topRight
        let trRadius = min(topRight, rect.width / 2, rect.height / 2)
        path.addLine(to: CGPoint(x: rect.maxX - trRadius, y: rect.minY))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - trRadius, y: rect.minY + trRadius),
            radius: trRadius,
            startAngle: 3 * .pi / 2,
            endAngle: 0,
            clockwise: true)

        // bottomRight
        let brRadius = min(bottomRight, rect.width / 2, rect.height / 2)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - brRadius))
        path.addArc(
            withCenter: CGPoint(x: rect.maxX - brRadius, y: rect.maxY - brRadius),
            radius: brRadius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true)

        // bottomLeft
        let blRadius = min(bottomLeft, rect.width / 2, rect.height / 2)
        path.addLine(to: CGPoint(x: rect.minX + blRadius, y: rect.maxY))
        path.addArc(
            withCenter: CGPoint(x: rect.minX + blRadius, y: rect.maxY - blRadius),
            radius: blRadius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true)
        path.close()

        return Path(path.cgPath)
    }
}

@available(iOS 13.0, *)
extension View {
    /// Adjust the cornerRadius to be inset with the specified padding.
    func cornerRadius(_ radius: CGFloat, padding: EdgeInsets) -> some View {
        clipShape(VariableRoundedCorner(
            topLeft: radius - max(padding.top, padding.leading) / 2,
            topRight: radius - max(padding.top, padding.trailing) / 2,
            bottomRight: radius - max(padding.bottom, padding.trailing) / 2,
            bottomLeft: radius - max(padding.bottom, padding.leading) / 2))
    }
}
