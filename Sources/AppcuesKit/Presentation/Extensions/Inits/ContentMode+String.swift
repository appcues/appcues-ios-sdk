//
//  ContentMode+String.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension ContentMode {

    /// Init `ContentMode` from an experience JSON model value.
    init?(string: String?) {
        switch string {
        case "fit": self = .fit
        case "fill": self = .fill
        default: return nil
        }
    }
}
