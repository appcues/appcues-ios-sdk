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
    init?(vertical: String?, horizontal: String?) {
        switch (vertical, horizontal) {
        case ("top", "leading"): self = .topLeading
        case ("top", "center"): self = .top
        case ("top", "trailing"): self = .topTrailing
        case ("center", "leading"): self = .leading
        case ("center", "center"): self = .center
        case ("center", "trailing"): self = .trailing
        case ("bottom", "leading"): self = .bottomLeading
        case ("bottom", "center"): self = .bottom
        case ("bottom", "trailing"): self = .bottomTrailing
        default: return nil
        }
    }
}
