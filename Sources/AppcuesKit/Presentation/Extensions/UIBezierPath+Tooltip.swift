//
//  UIBezierPath+Tooltip.swift
//  AppcuesKit
//
//  Created by Matt on 2023-01-31.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal struct Pointer {
    enum Edge {
        case top, bottom, leading, trailing
    }

    let edge: Edge
    let size: CGSize
    let offset: CGFloat
}

extension UIBezierPath {
    convenience init(tooltipAround mainRect: CGRect, cornerRadius: CGFloat, pointer: Pointer) {
        self.init()

        let triangle = Triangle(pointer: pointer, mainRect: mainRect, cornerRadius: cornerRadius)

        // Draw the path clockwise from top left

        if !triangle.overridesTopLeftCorner {
            let topLeft = CGPoint(x: mainRect.minX + cornerRadius, y: mainRect.minY + cornerRadius)
            addArc(withCenter: topLeft, radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
        } else {
            move(to: mainRect.origin)
        }

        if case .top = pointer.edge {
            addTriangle(triangle)
        }

        if !triangle.overridesTopRightCorner {
            let topRight = CGPoint(x: mainRect.maxX - cornerRadius, y: mainRect.minY + cornerRadius)
            addArc(withCenter: topRight, radius: cornerRadius, startAngle: -.pi / 2, endAngle: 0, clockwise: true)
        }

        if case .trailing = pointer.edge {
            addTriangle(triangle)
        }

        if !triangle.overridesBottomRightCorner {
            let bottomRight = CGPoint(x: mainRect.maxX - cornerRadius, y: mainRect.maxY - cornerRadius)
            addArc(withCenter: bottomRight, radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        }

        if case .bottom = pointer.edge {
            addTriangle(triangle)
        }

        if !triangle.overridesBottomLeftCorner {
            let bottomLeft = CGPoint(x: mainRect.minX + cornerRadius, y: mainRect.maxY - cornerRadius)
            addArc(withCenter: bottomLeft, radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        }

        if case .leading = pointer.edge {
            addTriangle(triangle)
        }

        close()
    }

    private func addTriangle(_ triangle: Triangle) {
        addLine(to: triangle.point1)
        addLine(to: triangle.point2)
        addLine(to: triangle.point3)
    }
}

private extension UIBezierPath {
    struct Triangle {
        // Points are ordered for a tooltip drawn clockwise
        let point1: CGPoint
        let point2: CGPoint
        let point3: CGPoint

        private(set) var overridesTopLeftCorner: Bool
        private(set) var overridesTopRightCorner: Bool
        private(set) var overridesBottomRightCorner: Bool
        private(set) var overridesBottomLeftCorner: Bool

        // swiftlint:disable:next cyclomatic_complexity function_body_length
        init(pointer: Pointer, mainRect: CGRect, cornerRadius: CGFloat) {
            overridesTopLeftCorner = false
            overridesTopRightCorner = false
            overridesBottomRightCorner = false
            overridesBottomLeftCorner = false

            switch pointer.edge {
            case .top:
                var triangleBounds = CGRect(
                    x: mainRect.midX - pointer.size.width / 2 + pointer.offset,
                    y: mainRect.minY - pointer.size.height,
                    width: pointer.size.width,
                    height: pointer.size.height)

                let point2X: CGFloat
                if triangleBounds.origin.x < cornerRadius {
                    // Check for collisions with leading corner
                    if triangleBounds.origin.x < 0 {
                        overridesTopLeftCorner = true
                        triangleBounds.origin.x = 0
                    } else {
                        triangleBounds.origin.x = cornerRadius
                    }
                    point2X = triangleBounds.minX
                } else if triangleBounds.origin.x > mainRect.maxX - pointer.size.width - cornerRadius {
                    // Check for collisions with trailing corner
                    if triangleBounds.origin.x > mainRect.maxX - pointer.size.width {
                        overridesTopRightCorner = true
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width
                    } else {
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width - cornerRadius
                    }
                    point2X = triangleBounds.maxX
                } else {
                    // Centered pointer
                    point2X = triangleBounds.midX
                }
                point1 = CGPoint(x: triangleBounds.minX, y: triangleBounds.maxY)
                point2 = CGPoint(x: point2X, y: triangleBounds.minY)
                point3 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.maxY)
            case .bottom:
                var triangleBounds = CGRect(
                    x: mainRect.midX - pointer.size.width / 2 + pointer.offset,
                    y: mainRect.maxY,
                    width: pointer.size.width,
                    height: pointer.size.height)

                let point2X: CGFloat
                if triangleBounds.origin.x < cornerRadius {
                    if triangleBounds.origin.x < 0 {
                        overridesBottomLeftCorner = true
                        triangleBounds.origin.x = 0
                    } else {
                        triangleBounds.origin.x = cornerRadius
                    }
                    point2X = triangleBounds.minX
                } else if triangleBounds.origin.x > mainRect.maxX - pointer.size.width - cornerRadius {
                    if triangleBounds.origin.x > mainRect.maxX - pointer.size.width {
                        overridesBottomRightCorner = true
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width
                    } else {
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width - cornerRadius
                    }
                    point2X = triangleBounds.maxX
                } else {
                    point2X = triangleBounds.midX
                }
                point1 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.minY)
                point2 = CGPoint(x: point2X, y: triangleBounds.maxY)
                point3 = CGPoint(x: triangleBounds.minX, y: triangleBounds.minY)
            case .leading:
                var triangleBounds = CGRect(
                    x: mainRect.minX - pointer.size.height,
                    y: (mainRect.midY - pointer.size.width / 2 + pointer.offset),
                    width: pointer.size.height,
                    height: pointer.size.width)

                let point2Y: CGFloat
                if triangleBounds.origin.y < cornerRadius {
                    if triangleBounds.origin.y < 0 {
                        overridesTopLeftCorner = true
                        triangleBounds.origin.y = 0
                    } else {
                        triangleBounds.origin.y = cornerRadius
                    }
                    point2Y = triangleBounds.minY
                } else if triangleBounds.origin.y > mainRect.maxY - pointer.size.width - cornerRadius {
                    if triangleBounds.origin.y > mainRect.maxY - pointer.size.width {
                        overridesBottomLeftCorner = true
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width
                    } else {
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width - cornerRadius
                    }
                    point2Y = triangleBounds.maxY
                } else {
                    point2Y = triangleBounds.midY
                }
                point1 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.maxY)
                point2 = CGPoint(x: triangleBounds.minX, y: point2Y)
                point3 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.minY)
            case .trailing:
                var triangleBounds = CGRect(
                    x: mainRect.maxX,
                    y: (mainRect.midY - pointer.size.width / 2 + pointer.offset),
                    width: pointer.size.height,
                    height: pointer.size.width)

                let point2Y: CGFloat
                if triangleBounds.origin.y < cornerRadius {
                    if triangleBounds.origin.y < 0 {
                        overridesTopRightCorner = true
                        triangleBounds.origin.y = 0
                    } else {
                        triangleBounds.origin.y = cornerRadius
                    }
                    point2Y = triangleBounds.minY
                } else if triangleBounds.origin.y > mainRect.maxY - pointer.size.width - cornerRadius {
                    if triangleBounds.origin.y > mainRect.maxY - pointer.size.width {
                        overridesBottomRightCorner = true
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width
                    } else {
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width - cornerRadius
                    }
                    point2Y = triangleBounds.maxY
                } else {
                    point2Y = triangleBounds.midY
                }
                point1 = CGPoint(x: triangleBounds.minX, y: triangleBounds.minY)
                point2 = CGPoint(x: triangleBounds.maxX, y: point2Y)
                point3 = CGPoint(x: triangleBounds.minX, y: triangleBounds.maxY)
            }
        }
    }
}
