//
//  LinearGradient+Init.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
extension LinearGradient {

    /// Init `LinearGradient` from an experience JSON model value.
    init?(rawGradient: ExperienceComponent.Style.RawGradient?) {
        let colors = rawGradient?.colors.compactMap { Color(dynamicColor: $0) }
        let startPoint = UnitPoint(string: rawGradient?.startPoint)
        let endPoint = UnitPoint(string: rawGradient?.endPoint)

        guard let colors = colors, let startPoint = startPoint, let endPoint = endPoint else {
            return nil
        }

        self = LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
    }
}

@available(iOS 13.0, *)
extension UnitPoint {

    /// Init `UnitPoint` from an experience JSON model value.
    init?(string: String?) {
        switch string {
        case "bottom": self = .bottom
        case "bottomLeading": self = .bottomLeading
        case "bottomTrailing": self = .bottomTrailing
        case "center": self = .center
        case "leading": self = .leading
        case "trailing": self = .trailing
        case "top": self = .top
        case "topLeading": self = .topLeading
        case "topTrailing": self = .topTrailing
        default: return nil
        }
    }
}
