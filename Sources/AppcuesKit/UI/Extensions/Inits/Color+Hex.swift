//
//  Color+Hex.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension Color {

    /// Init `Color` from an experience JSON model value.
    init?(hex: String?) {
        guard let components = hex?.toRGBAComponents else { return nil }

        self.init(
            .sRGB,
            red: Double(components.r) / 255,
            green: Double(components.g) / 255,
            blue: Double(components.b) / 255,
            opacity: Double(components.a) / 255
        )
    }
}

extension String {
    // swiftlint:disable:next large_tuple
    var toRGBAComponents: (r: UInt64, g: UInt64, b: UInt64, a: UInt64) {
        let hex = self.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

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

        return (r, g, b, a)
    }
}
