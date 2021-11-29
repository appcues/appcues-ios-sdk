//
//  UIColor+Hex.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-29.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension UIColor {

    /// Init `UIColor` from an experience JSON model value.
    convenience init?(hex: String?) {
        guard let components = hex?.toRGBAComponents else { return nil }

        self.init(
            red: Double(components.r) / 255,
            green: Double(components.g) / 255,
            blue: Double(components.b) / 255,
            alpha: Double(components.a) / 255
        )
    }
}
