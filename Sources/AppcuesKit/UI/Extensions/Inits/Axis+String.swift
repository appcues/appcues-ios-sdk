//
//  Axis+String.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-25.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension Axis {

    /// Init `Axis` from an experience JSON model value.
    init?(string: String?) {
        switch string {
        case "horizontal": self = .horizontal
        case "vertical": self = .vertical
        default: return nil
        }
    }
}
