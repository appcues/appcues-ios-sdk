//
//  CGRect+Resize.swift
//  AppcuesKit
//
//  Created by James Ellis on 5/1/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal extension CGRect {
    var zeroed: CGRect {
        CGRect(x: midX, y: midY, width: 0, height: 0)
    }

    func spread(by spreadRadius: CGFloat?) -> CGRect {
        guard let radius = spreadRadius else { return self }
        return self.insetBy(dx: -radius, dy: -radius)
    }
}
