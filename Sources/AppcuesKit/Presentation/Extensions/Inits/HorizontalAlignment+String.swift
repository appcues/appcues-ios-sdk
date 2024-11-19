//
//  HorizontalAlignment+String.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension HorizontalAlignment {

    /// Init `HorizontalAlignment` from an experience JSON model value.
    init?(string: String?) {
        switch string {
        case "center": self = .center
        case "leading": self = .leading
        case "trailing": self = .trailing
        default: return nil
        }
    }
}
