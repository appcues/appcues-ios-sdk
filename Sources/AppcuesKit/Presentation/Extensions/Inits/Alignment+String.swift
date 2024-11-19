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
        case ("top", "center"), ("top", nil): self = .top
        case ("top", "trailing"): self = .topTrailing
        case ("center", "leading"), (nil, "leading"): self = .leading
        case ("center", "center"), (nil, nil): self = .center
        case ("center", "trailing"), (nil, "trailing"): self = .trailing
        case ("bottom", "leading"): self = .bottomLeading
        case ("bottom", "center"), ("bottom", nil): self = .bottom
        case ("bottom", "trailing"): self = .bottomTrailing
        default: return nil
        }
    }
}
