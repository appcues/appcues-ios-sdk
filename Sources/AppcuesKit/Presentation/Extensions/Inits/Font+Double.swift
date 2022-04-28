//
//  Font+Double.swift
//  Appcues
//
//  Created by Matt on 2021-11-02.
//

import SwiftUI

@available(iOS 13.0, *)
extension Font {

    /// Init `Font` from an experience JSON model values.
    init?(name: String?, size: Double?, weight: Double?) {
        guard let size = CGFloat(size) else { return nil }
        guard let name = name else {
            self = .system(size: size, weight: Font.Weight(double: weight) ?? .regular)
            return
        }

        // A space is invalid for PostScript font names, and so we can safely avoid collisions with a custom font named "System".
        if name.starts(with: "System ") {
            // Expected format is `System $Design $Weight`.
            let parts = name.split(separator: " ")
            if parts.count == 3 {
                self = .system(
                    size: size,
                    weight: Font.Weight(string: String(parts[2])) ?? .regular,
                    design: Font.Design(string: String(parts[1])) ?? .default
                )
            } else {
                self = .system(size: size)
            }
        } else {
            if let weight = weight {
                self = .custom(name, size: size, weight: weight)
            } else {
                self = .custom(name, size: size)
            }
        }
    }

    static func custom(_ name: String, size: CGFloat = UIFont.labelFontSize, weight: CGFloat = 0) -> Font {
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: name,
            kCTFontVariationAttribute as UIFontDescriptor.AttributeName: [
                // 0x77676874 == OpenType variation axis tag for `wght`
                // https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6fvar.html
                0x77676874: weight
            ]
        ])

        return Font(UIFont(descriptor: descriptor, size: size))
    }
}

@available(iOS 13.0, *)
extension Font.Weight {

    /// Init `Font.Weight` from an experience JSON fontName keyword.
    init?(string: String?) {
        switch string {
        case "Black": self = .black
        case "Heavy": self = .heavy
        case "Bold": self = .bold
        case "Semibold": self = .semibold
        case "Medium": self = .medium
        case "Regular": self = .regular
        case "Light": self = .light
        case "Thin": self = .thin
        case "Ultralight": self = .ultraLight
        default: return nil
        }
    }

    /// Init `Font.Weight` from an experience JSON model value.
    init?(double: Double?) {
        guard let double = double else { return nil }

        switch double {
        case 850...1_000: self = .black
        case 750..<850: self = .heavy
        case 650..<750: self = .bold
        case 550..<650: self = .semibold
        case 450..<550: self = .medium
        case 350..<450: self = .regular
        case 250..<350: self = .light
        case 150..<250: self = .thin
        case 1..<150: self = .ultraLight
        default: return nil
        }
    }
}

@available(iOS 13.0, *)
extension Font.Design {

    /// Init `Font.Design` from an experience JSON fontName keyword.
    init?(string: String?) {
        switch string {
        case "Default": self = .default
        case "Monospaced": self = .monospaced
        case "Rounded": self = .rounded
        case "Serif": self = .serif
        default: return nil
        }
    }
}
