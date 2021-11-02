//
//  Font.Weight+String.swift
//  Appcues
//
//  Created by Matt on 2021-11-02.
//

import SwiftUI

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
