//
//  CGSize+PointerSize.swift
//  AppcuesKit
//
//  Created by Matt on 2023-03-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

extension CGSize {
    // How does this work?
    // We're interested in the radius value such that the arc from outer circle (C1) and arc from the inner circle (C2)
    // intersect, drawing a continuous line for the pointer rather than C2 exceeding C1 and there being an odd straight line
    // while the path backtracks.
    // There's a few constraints we know:
    // 1. The angle of the line between C1 and C2 (perpendicular to the side of the pointer triangle)
    // 2. The x value of the center of C2 must be in the middle of the pointer (so pointerSize.width / 2)
    // 3. The y value of the center of C2 (h) can be calculated from the tip of the pointer
    // 4. The distance between C1 and C2 is 2 * radius
    // 5. The center of C1 can be calculated by projecting from C1 distance 2 * radius by the angle
    // 6. The y value of the center of C1 must be exactly -radius from the base (so pointerSize.height - radius)
    var maxPointerCornerRadius: CGFloat {
        let pt1 = CGPoint(x: 0, y: self.height)
        let pt2 = CGPoint(x: self.width / 2, y: 0)

        let angle = atan2(pt1.y, pt2.x)                      // (1)
        // let h = r / cos(angle)                            // (3)
        // let centerC2 = CGPoint(
        //    x: pt2.x,                                      // (2)
        //    y: pt2.y + h)                                  // (3)

        // The position of centerC1, given centerC2 and r
        // let centerC1 = CGPoint(
        //    x: centerC2.x - cos(angle - .pi / 2) * r * 2,  // (4, 5)
        //    y: centerC2.y + sin(angle - .pi / 2) * r * 2)  // (4, 5)

        // We know pt1.y - r = centerC1.y                    // (6)
        //      => r = pt1.y - centerC1.y

        // Substitute and solve for r:
        let radius = (pt1.y - pt2.y) / (1 + 2 * sin(angle - .pi / 2) + (1 / cos(angle)))

        return radius
    }
}
