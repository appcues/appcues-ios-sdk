//
//  CGPoint+Relative.swift
//  AppcuesKit
//
//  Created by James Ellis on 5/1/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import CoreGraphics

internal extension CGPoint {
    func relative(in size: CGSize) -> CGPoint {
        CGPoint(x: self.x / size.width, y: self.y / size.height)
    }
}
