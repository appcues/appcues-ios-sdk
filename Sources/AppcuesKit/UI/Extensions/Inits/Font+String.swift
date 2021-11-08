//
//  Font+String.swift
//  Appcues
//
//  Created by Matt on 2021-11-02.
//

import SwiftUI

extension Font {

    /// Init `Font` from an experience JSON model values.
    init?(name: String?, size: Double?, weight: String?) {
        guard let size = CGFloat(size) else { return nil }

        if let name = name, name != "System" {
            self = .custom(name, size: size)
        } else {
            self = .system(size: size, weight: Font.Weight(string: weight) ?? .regular)
        }
    }
}

extension Font.Weight {

    /// Init `Font.Weight` from an experience JSON model value.
    init?(string: String?) {
        switch string {
        case "black": self = .black
        case "bold": self = .bold
        case "heavy": self = .heavy
        case "light": self = .light
        case "medium": self = .medium
        case "regular": self = .regular
        case "semibold": self = .semibold
        case "thin": self = .thin
        case "ultraLight": self = .ultraLight
        default: return nil
        }
    }
}
