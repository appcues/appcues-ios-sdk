//
//  Color+DynamicColor.swift
//  AppcuesKit
//
//  Created by Matt on 2021-12-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension UIColor {
    convenience init?(dynamicColor: ExperienceComponent.Style.DynamicColor?) {
        guard let semanticColor = dynamicColor else { return nil }

        self.init { traitCollection in
            if let dark = UIColor(hex: semanticColor.dark), traitCollection.userInterfaceStyle == .dark {
                return dark
            } else {
                return UIColor(hex: semanticColor.light) ?? .label
            }
        }
    }
}

extension Color {
    init?(dynamicColor: ExperienceComponent.Style.DynamicColor?) {
        guard let uiColor = UIColor(dynamicColor: dynamicColor) else { return nil }
        self.init(uiColor)
    }
}
