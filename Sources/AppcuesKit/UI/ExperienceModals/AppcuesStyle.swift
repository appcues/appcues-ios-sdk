//
//  AppcuesStyle.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesStyle: ViewModifier {
    let font: Font?
    let lineSpacing: CGFloat?
    let alignment: TextAlignment?
    let foregroundColor: Color?
    let backgroundColor: Color?
    let backgroundGradient: LinearGradient?
    let cornerRadius: CGFloat?
    let borderColor: Color?
    let borderWidth: CGFloat?

    init(from model: ExperienceComponent.Style?) {
        self.font = Font(name: model?.fontName, size: model?.fontSize, weight: model?.fontWeight)
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
            .ifLet(font) { view, val in
                view.font(val)
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
