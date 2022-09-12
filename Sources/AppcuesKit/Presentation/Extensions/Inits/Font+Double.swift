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
    init?(name: String?, size: Double?) {
        guard let size = CGFloat(size) else { return nil }
        guard let name = name else {
            self = .system(size: size)
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
            self = .custom(name, size: size)
        }
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

@available(iOS 13.0, *)
extension UIFont {
    static func matching(name: String?, size: Double?) -> UIFont? {
        guard let size = CGFloat(size) else { return nil }
        guard let name = name else {
            return .systemFont(ofSize: size)
        }

        // A space is invalid for PostScript font names, and so we can safely avoid collisions with a custom font named "System".
        if name.starts(with: "System ") {
            // Expected format is `System $Design $Weight`.
            let parts = name.split(separator: " ")
            if parts.count == 3 {
                let systemFont = UIFont.systemFont(ofSize: size, weight: UIFont.Weight(string: String(parts[2])) ?? .regular)
                let design = UIFontDescriptor.SystemDesign(string: String(parts[1])) ?? .default

                if let descriptor = systemFont.fontDescriptor.withDesign(design) {
                    return UIFont(descriptor: descriptor, size: size)
                } else {
                    return systemFont
                }
            } else {
                return .systemFont(ofSize: size)
            }
        } else {
            return UIFont(name: name, size: size)
        }
    }
}

@available(iOS 13.0, *)
extension UIFont.Weight {

    /// Init `UIFont.Weight` from an experience JSON fontName keyword.
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
}

@available(iOS 13.0, *)
extension UIFontDescriptor.SystemDesign {

    /// Init `UIFontDescriptor.SystemDesign` from an experience JSON fontName keyword.
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
