//
//  AppcuesStyle.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesStyle {
    let font: Font?
    let letterSpacing: CGFloat?
    let lineSpacing: CGFloat?
    let textAlignment: TextAlignment?
    let foregroundColor: Color?
    let backgroundColor: Color?
    let backgroundGradient: LinearGradient?
    let shadow: ExperienceComponent.Style.RawShadow?
    let cornerRadius: CGFloat?
    let borderColor: Color?
    let borderWidth: CGFloat?

    init(from model: ExperienceComponent.Style?) {
        self.font = Font(name: model?.fontName, size: model?.fontSize, weight: model?.fontWeight)
        self.letterSpacing = CGFloat(model?.letterSpacing)
        self.lineSpacing = CGFloat(model?.lineSpacing)
        self.textAlignment = TextAlignment(string: model?.textAlignment)
        self.foregroundColor = Color(semanticColor: model?.foregroundColor)
        self.backgroundColor = Color(semanticColor: model?.backgroundColor)
        self.backgroundGradient = LinearGradient(rawGradient: model?.backgroundGradient)
        self.shadow = model?.shadow
        self.cornerRadius = CGFloat(model?.cornerRadius)
        self.borderColor = Color(semanticColor: model?.borderColor)
        self.borderWidth = CGFloat(model?.borderWidth)
    }
}
