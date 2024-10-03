//
//  ExperienceWrapperViewController+DragDirection.swift
//  AppcuesKit
//
//  Created by Matt on 2024-09-27.
//  Copyright © 2024 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
extension ExperienceWrapperViewController {
    struct DragDirection {
        enum Edge {
            case left, right, up, down
        }

        let xDirection: Edge
        let yDirection: Edge

        private let initialPoint: CGPoint
        private let newPoint: CGPoint

        init(initial: CGPoint, new: CGPoint) {
            self.initialPoint = initial
            self.newPoint = new
            self.xDirection = new.x > initial.x ? .right : .left
            self.yDirection = new.y > initial.y ? .down : .up
        }

        /// Determine which edges are eligible for drag-to-dismiss.
        static func allowedEdges(horizontalAlignment: HorizontalAlignment, verticalAlignment: VerticalAlignment) -> Set<Edge> {
            switch (horizontalAlignment, verticalAlignment) {
            case (.leading, _):
                return [.left]
            case (.trailing, _):
                return [.right]
            case (_, .top):
                return [.up]
            case (_, .bottom):
                return [.down]
            default:
                return []
            }
        }

        /// Calculate the new center point, applying rubber-banding if dragging towards an ineligible edge.
        func newPoint(allowedEdges: Set<Edge>) -> CGPoint {
            let newX: CGFloat
            let newY: CGFloat

            if allowedEdges.contains(xDirection) {
                newX = newPoint.x
            } else {
                let deltaX = newPoint.x - initialPoint.x
                newX = initialPoint.x + (deltaX > 0 ? pow(deltaX, 0.5) : -pow(-deltaX, 0.5))
            }

            if allowedEdges.contains(yDirection) {
                newY = newPoint.y
            } else {
                let deltaY = newPoint.y - initialPoint.y
                newY = initialPoint.y + (deltaY > 0 ? pow(deltaY, 0.5) : -pow(-deltaY, 0.5))
            }

            return CGPoint(x: newX, y: newY)
        }

        /// Confirm if the new position will be entirely outsize the visible bounds on an eligible edge.
        func isSufficientToDismiss(allowedEdges: Set<Edge>, size: CGRect, bounds: CGRect) -> Bool {
            if allowedEdges.contains(.left) && newPoint.x + size.width / 2 < bounds.minX {
                return true
            }

            if allowedEdges.contains(.right) && newPoint.x - size.width / 2 > bounds.maxX {
                return true
            }

            if allowedEdges.contains(.up) && newPoint.y + size.height / 2 < bounds.minY {
                return true
            }

            if allowedEdges.contains(.down) && newPoint.y - size.height / 2 > bounds.maxY {
                return true
            }

            return false
        }
    }
}
