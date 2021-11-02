//
//  Alignment+String.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension Alignment {

    /// Init `Alignment` from an experience JSON model value.
    init?(string: String?) {
        switch string {
        case "center": self = .center
        case "topLeading": self = .topLeading
        case "top": self = .top
        case "leading": self = .leading
        case "trailing": self = .trailing
        case "bottomLeading": self = .bottomLeading
        case "bottom": self = .bottom
        case "bottomTrailing": self = .bottomTrailing
        default: return nil
        }
    }
}
