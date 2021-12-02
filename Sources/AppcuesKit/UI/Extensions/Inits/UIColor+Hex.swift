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
        guard let hex = hex?.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) else { return nil }

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        // swiftlint:disable:next identifier_name
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // RGBA (32-bit)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}
