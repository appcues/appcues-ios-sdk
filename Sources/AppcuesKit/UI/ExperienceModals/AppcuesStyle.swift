//
//  AppcuesStyle.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesStyle: ViewModifier {
    let fontSize: CGFloat?
    let fontWeight: Font.Weight
    let lineSpacing: CGFloat?
    let alignment: TextAlignment?
    let foregroundColor: Color?
    let backgroundColor: Color?
    let backgroundGradient: LinearGradient?
    let cornerRadius: CGFloat?
    let borderColor: Color?
    let borderWidth: CGFloat?

    init(from model: ExperienceComponent.Style?) {
        self.fontSize = CGFloat(model?.fontSize)
        self.fontWeight = Font.Weight(string: model?.fontWeight) ?? .regular
        self.lineSpacing = CGFloat(model?.lineSpacing)
        self.alignment = TextAlignment(string: model?.alignment)
        self.foregroundColor = Color(hex: model?.foregroundColor)
        self.backgroundColor = Color(hex: model?.backgroundColor)
        self.backgroundGradient = LinearGradient(rawGradient: model?.backgroundGradient)
        self.cornerRadius = CGFloat(model?.cornerRadius)
        self.borderColor = Color(hex: model?.borderColor)
        self.borderWidth = CGFloat(model?.borderWidth)
    }

    func body(content: Content) -> some View {
        content
            .ifLet(fontSize) { view, val in
                view.font(.system(size: val, weight: fontWeight))
            }
            .ifLet(lineSpacing) { view, val in
                view.lineSpacing(val)
            }
            .ifLet(foregroundColor) { view, val in
                view.foregroundColor(val)
            }
            .ifLet(backgroundColor) { view, val in
                view.background(val)
            }
            .ifLet(backgroundGradient) { view, val in
                view.background(val)
            }
            .ifLet(cornerRadius) { view, val in
                view.cornerRadius(val)
            }
            .ifLet(borderColor, borderWidth) { view, val1, val2 in
                view.overlay(
                    RoundedRectangle(cornerRadius: cornerRadius ?? 0)
                        .stroke(val1, lineWidth: val2)
                )
            }
    }
}
