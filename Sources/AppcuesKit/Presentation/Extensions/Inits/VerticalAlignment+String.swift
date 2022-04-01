//
//  VerticalAlignment+String.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
extension VerticalAlignment {

    /// Init `VerticalAlignment` from an experience JSON model value.
    init?(string: String?) {
        switch string {
        case "center": self = .center
        case "top": self = .top
        case "bottom": self = .bottom
        default: return nil
        }
    }
}
