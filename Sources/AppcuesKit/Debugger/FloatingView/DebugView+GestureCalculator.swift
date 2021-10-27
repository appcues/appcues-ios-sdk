//
//  DebugView+GestureCalculator.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

// swiftlint:disable identifier_name

extension DebugView {
    struct GestureCalculator {
        /// Calculate a scaled damping value from an initial magnitude.
        func dynamicDamping(magnitude x: CGFloat) -> CGFloat {
            let x = min(x, 5_000)
            // Return scaled values between 0.4 and 0.85
            return 1 - ((0.6 - 0.15) * (x - 100) / (5_000 - 100) + 0.15)
        }

        /// Distance traveled after decelerating to zero velocity at a constant rate.
        func project(initialVelocity: CGFloat) -> CGFloat {
            let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
            return (initialVelocity / 1_000) * decelerationRate / (1 - decelerationRate)
        }

        /// Calculates the relative velocity needed for the initial velocity of the animation.
        func relativeVelocity(forVelocity velocity: CGFloat, from currentValue: CGFloat, to targetValue: CGFloat) -> CGFloat {
            guard currentValue - targetValue != 0 else { return 0 }
            return velocity / (targetValue - currentValue)
        }

        /// Calculates an point on the provided rect based on the initial and projected points.
        func restingPoint(from initial: CGPoint, to projected: CGPoint, within rect: CGRect) -> CGPoint {
            var pt: CGPoint

            if !rect.contains(initial) {
                pt = restingPoint(outOfBounds: initial, within: rect)
            } else if initial.distance(from: projected) < 500 {
                pt = restingPoint(lowVelocity: initial, within: rect)
            } else {
                let angle = atan2(projected.y - initial.y, projected.x - initial.x)
                let dx = cos(angle)
                let dy = sin(angle)

                // Add rect.min to each to account for CGRect where x,y != 0
                var t1 = (rect.width + rect.minX - initial.x) / dx
                var t2 = (rect.height + rect.minY - initial.y) / dy
                var t3 = (rect.minX - initial.x) / dx
                var t4 = (rect.minY - initial.y) / dy

                if t1 <= 0 {
                    t1 = CGFloat.greatestFiniteMagnitude
                }
                if t2 <= 0 {
                    t2 = CGFloat.greatestFiniteMagnitude
                }
                if t3 <= 0 {
                    t3 = CGFloat.greatestFiniteMagnitude
                }
                if t4 <= 0 {
                    t4 = CGFloat.greatestFiniteMagnitude
                }

                let t = min(t1, t2, t3, t4)

                pt = CGPoint(x: initial.x + t * dx, y: initial.y + t * dy)
            }

            // If we're intersecting along the top or the bottom, instead snap to the nearest vertical edge
            if pt.y == rect.minY || pt.y == rect.maxY {
                if pt.x < rect.midX {
                    pt.x = rect.minX
                } else {
                    pt.x = rect.maxX
                }
            }

            return pt
        }

        private func restingPoint(outOfBounds initial: CGPoint, within rect: CGRect) -> CGPoint {
            var pt = CGPoint(x: initial.x, y: initial.y)

            // Handle initial point outside of the bound rect
            // Just snap the out-of-bounds value(s) to the rect edges
            if initial.x < rect.minX {
                pt.x = rect.minX
            }
            if initial.x > rect.maxX {
                pt.x = rect.maxX
            }
            if initial.y < rect.minY {
                pt.y = rect.minY
            }
            if initial.y > rect.maxY {
                pt.y = rect.maxY
            }

            return pt
        }

        private func restingPoint(lowVelocity initial: CGPoint, within rect: CGRect) -> CGPoint {
            var pt = CGPoint(x: initial.x, y: initial.y)

            // If there's not enough velocity, snap straight to nearest edge
            if initial.x < rect.midX {
                pt.x = rect.minX
            } else {
                pt.x = rect.maxX
            }

            return pt
        }
    }
}
