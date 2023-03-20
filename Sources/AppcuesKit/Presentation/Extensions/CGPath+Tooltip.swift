//
//  CGPath+Tooltip.swift
//  AppcuesKit
//
//  Created by Matt on 2023-01-31.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal struct Pointer {
    enum Edge {
        case top, bottom, left, right
    }

    let edge: Edge
    let size: CGSize
    let cornerRadius: CGFloat
    let offset: CGFloat

    func pathInfo(mainRect: CGRect, boxCornerRadius: CGFloat) -> Pointer.PathInfo {
        PathInfo(pointer: self, mainRect: mainRect, boxCornerRadius: boxCornerRadius)
    }
}

extension CGPath {
    static func tooltip(around mainRect: CGRect, boxCornerRadius: CGFloat, pointer: Pointer) -> CGPath {
        let path = CGMutablePath()
        let pointerPathInfo = pointer.pathInfo(mainRect: mainRect, boxCornerRadius: boxCornerRadius)

        // Draw the path clockwise from top left

        if !pointerPathInfo.overridesTopLeftCorner {
            let topLeft = CGPoint(x: mainRect.minX + boxCornerRadius, y: mainRect.minY + boxCornerRadius)
            path.addRelativeArc(center: topLeft, radius: boxCornerRadius, startAngle: .pi, delta: .pi / 2)
        } else {
            path.move(to: mainRect.origin)
        }

        if case .top = pointer.edge {
            path.addPointer(pointerPathInfo)
        }

        if !pointerPathInfo.overridesTopRightCorner {
            let topRight = CGPoint(x: mainRect.maxX - boxCornerRadius, y: mainRect.minY + boxCornerRadius)
            path.addRelativeArc(center: topRight, radius: boxCornerRadius, startAngle: 3 * .pi / 2, delta: .pi / 2)
        }

        if case .right = pointer.edge {
            path.addPointer(pointerPathInfo)
        }

        if !pointerPathInfo.overridesBottomRightCorner {
            let bottomRight = CGPoint(x: mainRect.maxX - boxCornerRadius, y: mainRect.maxY - boxCornerRadius)
            path.addRelativeArc(center: bottomRight, radius: boxCornerRadius, startAngle: 0, delta: .pi / 2)
        }

        if case .bottom = pointer.edge {
            path.addPointer(pointerPathInfo)
        }

        if !pointerPathInfo.overridesBottomLeftCorner {
            let bottomLeft = CGPoint(x: mainRect.minX + boxCornerRadius, y: mainRect.maxY - boxCornerRadius)
            path.addRelativeArc(center: bottomLeft, radius: boxCornerRadius, startAngle: .pi / 2, delta: .pi / 2)
        }

        if case .left = pointer.edge {
            path.addPointer(pointerPathInfo)
        }

        path.closeSubpath()
        return path
    }
}

private extension CGMutablePath {
    func addPointer(_ pathInfo: Pointer.PathInfo) {
        if pathInfo.cornerRadius == 0 {
            addLine(to: pathInfo.point1)
            addLine(to: pathInfo.point2)
            addLine(to: pathInfo.point3)
        } else {
            if pathInfo.drawStraightPoint1 {
                // Can't round the straight edge
                addLine(to: pathInfo.point1)
            } else {
                addArc(tangent1End: pathInfo.point1, tangent2End: pathInfo.point2, radius: pathInfo.cornerRadius)
            }

            addArc(tangent1End: pathInfo.point2, tangent2End: pathInfo.point3, radius: pathInfo.cornerRadius)

            if pathInfo.drawStraightPoint3 {
                // Can't round the straight edge
                addLine(to: pathInfo.point3)
            } else {
                addArc(tangent1End: pathInfo.point3, tangent2End: pathInfo.point4, radius: pathInfo.cornerRadius)
            }
        }
    }
}

extension Pointer {
    struct PathInfo {
        // Points are ordered for a tooltip drawn clockwise
        let point1: CGPoint
        let point2: CGPoint
        let point3: CGPoint

        let cornerRadius: CGFloat

        // Control points for rounded pointer arc calculations
        let point0: CGPoint
        let point4: CGPoint

        private(set) var overridesTopLeftCorner: Bool
        private(set) var overridesTopRightCorner: Bool
        private(set) var overridesBottomRightCorner: Bool
        private(set) var overridesBottomLeftCorner: Bool

        private(set) var drawStraightPoint1: Bool
        private(set) var drawStraightPoint3: Bool

        // swiftlint:disable:next cyclomatic_complexity function_body_length
        init(pointer: Pointer, mainRect: CGRect, boxCornerRadius: CGFloat) {
            self.cornerRadius = pointer.cornerRadius

            overridesTopLeftCorner = false
            overridesTopRightCorner = false
            overridesBottomRightCorner = false
            overridesBottomLeftCorner = false

            drawStraightPoint1 = false
            drawStraightPoint3 = false

            switch pointer.edge {
            case .top:
                var triangleBounds = CGRect(
                    x: mainRect.midX - pointer.size.width / 2 + pointer.offset,
                    y: mainRect.minY - pointer.size.height,
                    width: pointer.size.width,
                    height: pointer.size.height)

                let point2X: CGFloat
                if triangleBounds.origin.x < boxCornerRadius {
                    // Check for collisions with left corner
                    if triangleBounds.origin.x < 0 {
                        overridesTopLeftCorner = true
                        triangleBounds.origin.x = 0
                    } else {
                        triangleBounds.origin.x = boxCornerRadius
                    }
                    point2X = triangleBounds.minX
                    drawStraightPoint1 = true
                } else if triangleBounds.origin.x > mainRect.maxX - pointer.size.width - boxCornerRadius {
                    // Check for collisions with right corner
                    if triangleBounds.origin.x > mainRect.maxX - pointer.size.width {
                        overridesTopRightCorner = true
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width
                    } else {
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width - boxCornerRadius
                    }
                    point2X = triangleBounds.maxX
                    drawStraightPoint3 = true
                } else {
                    // Centered pointer
                    point2X = triangleBounds.midX
                }
                point1 = CGPoint(x: triangleBounds.minX, y: triangleBounds.maxY)
                point2 = CGPoint(x: point2X, y: triangleBounds.minY)
                point3 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.maxY)

                point0 = CGPoint(x: mainRect.minX + boxCornerRadius, y: point1.y)
                point4 = CGPoint(x: mainRect.maxX - boxCornerRadius, y: point3.y)
            case .bottom:
                var triangleBounds = CGRect(
                    x: mainRect.midX - pointer.size.width / 2 + pointer.offset,
                    y: mainRect.maxY,
                    width: pointer.size.width,
                    height: pointer.size.height)

                let point2X: CGFloat
                if triangleBounds.origin.x < boxCornerRadius {
                    if triangleBounds.origin.x < 0 {
                        overridesBottomLeftCorner = true
                        triangleBounds.origin.x = 0
                    } else {
                        triangleBounds.origin.x = boxCornerRadius
                    }
                    point2X = triangleBounds.minX
                    drawStraightPoint3 = true
                } else if triangleBounds.origin.x > mainRect.maxX - pointer.size.width - boxCornerRadius {
                    if triangleBounds.origin.x > mainRect.maxX - pointer.size.width {
                        overridesBottomRightCorner = true
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width
                    } else {
                        triangleBounds.origin.x = mainRect.maxX - pointer.size.width - boxCornerRadius
                    }
                    point2X = triangleBounds.maxX
                    drawStraightPoint1 = true
                } else {
                    point2X = triangleBounds.midX
                }
                point1 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.minY)
                point2 = CGPoint(x: point2X, y: triangleBounds.maxY)
                point3 = CGPoint(x: triangleBounds.minX, y: triangleBounds.minY)

                point0 = CGPoint(x: mainRect.maxX - boxCornerRadius, y: point1.y)
                point4 = CGPoint(x: mainRect.minX + boxCornerRadius, y: point3.y)
            case .left:
                var triangleBounds = CGRect(
                    x: mainRect.minX - pointer.size.height,
                    y: (mainRect.midY - pointer.size.width / 2 + pointer.offset),
                    width: pointer.size.height,
                    height: pointer.size.width)

                let point2Y: CGFloat
                if triangleBounds.origin.y < boxCornerRadius {
                    if triangleBounds.origin.y < 0 {
                        overridesTopLeftCorner = true
                        triangleBounds.origin.y = 0
                    } else {
                        triangleBounds.origin.y = boxCornerRadius
                    }
                    point2Y = triangleBounds.minY
                    drawStraightPoint3 = true
                } else if triangleBounds.origin.y > mainRect.maxY - pointer.size.width - boxCornerRadius {
                    if triangleBounds.origin.y > mainRect.maxY - pointer.size.width {
                        overridesBottomLeftCorner = true
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width
                    } else {
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width - boxCornerRadius
                    }
                    point2Y = triangleBounds.maxY
                    drawStraightPoint1 = true
                } else {
                    point2Y = triangleBounds.midY
                }
                point1 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.maxY)
                point2 = CGPoint(x: triangleBounds.minX, y: point2Y)
                point3 = CGPoint(x: triangleBounds.maxX, y: triangleBounds.minY)

                point0 = CGPoint(x: point1.x, y: mainRect.maxY - boxCornerRadius)
                point4 = CGPoint(x: point3.x, y: mainRect.minY + boxCornerRadius)
            case .right:
                var triangleBounds = CGRect(
                    x: mainRect.maxX,
                    y: (mainRect.midY - pointer.size.width / 2 + pointer.offset),
                    width: pointer.size.height,
                    height: pointer.size.width)

                let point2Y: CGFloat
                if triangleBounds.origin.y < boxCornerRadius {
                    if triangleBounds.origin.y < 0 {
                        overridesTopRightCorner = true
                        triangleBounds.origin.y = 0
                    } else {
                        triangleBounds.origin.y = boxCornerRadius
                    }
                    point2Y = triangleBounds.minY
                    drawStraightPoint1 = true
                } else if triangleBounds.origin.y > mainRect.maxY - pointer.size.width - boxCornerRadius {
                    if triangleBounds.origin.y > mainRect.maxY - pointer.size.width {
                        overridesBottomRightCorner = true
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width
                    } else {
                        triangleBounds.origin.y = mainRect.maxY - pointer.size.width - boxCornerRadius
                    }
                    point2Y = triangleBounds.maxY
                    drawStraightPoint3 = true
                } else {
                    point2Y = triangleBounds.midY
                }
                point1 = CGPoint(x: triangleBounds.minX, y: triangleBounds.minY)
                point2 = CGPoint(x: triangleBounds.maxX, y: point2Y)
                point3 = CGPoint(x: triangleBounds.minX, y: triangleBounds.maxY)

                point0 = CGPoint(x: point1.x, y: mainRect.minY + boxCornerRadius)
                point4 = CGPoint(x: point3.x, y: mainRect.maxY - boxCornerRadius)
            }
        }
    }
}
