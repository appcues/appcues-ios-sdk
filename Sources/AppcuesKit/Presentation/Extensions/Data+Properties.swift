//
//  Data+Properties.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-21.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
import ImageIO

extension Data {
    var isAnimatedImage: Bool {
        if let source = CGImageSourceCreateWithData(self as CFData, nil) {
            return CGImageSourceGetCount(source) > 1
        }
        return false
    }
}
