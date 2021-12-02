//
//  View+Appcues.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension View {
    func setupActions(_ actions: [ExperienceStepViewModel.ActionType: [() -> Void]]) -> some View {
        // simultaneousGesture is needed to make a Button support any of these gestures.
        self
            .ifLet(actions[.tap]) { view, actionHandlers in
                view.simultaneousGesture(TapGesture().onEnded {
                    actionHandlers.forEach { actionHandler in actionHandler() }
                })
            }
            .ifLet(actions[.longPress]) { view, actionHandlers in
                view.simultaneousGesture(LongPressGesture().onEnded { _ in
                    actionHandlers.forEach { actionHandler in actionHandler() }
                })
            }
    }

    func applyForegroundStyle(_ style: AppcuesStyle) -> some View {
        self
            .ifLet(style.font) { view, val in
                view.font(val)
            }
            .ifLet(style.lineSpacing) { view, val in
                view.lineSpacing(val)
            }
            .ifLet(style.foregroundColor) { view, val in
                view.foregroundColor(val)
            }
    }

    func applyInternalLayout(_ layout: AppcuesLayout) -> some View {
        self
            .padding(layout.padding)
            .frame(width: layout.width, height: layout.height)
            .if(layout.fillWidth) { view in
                view.frame(maxWidth: .infinity)
            }
    }

    func applyBackgroundStyle(_ style: AppcuesStyle) -> some View {
        self
            .ifLet(style.backgroundColor) { view, val in
                view.background(val)
            }
            .ifLet(style.backgroundGradient) { view, val in
                view.background(val)
            }
            .ifLet(style.cornerRadius) { view, val in
                view.cornerRadius(val)
            }
            .ifLet(style.shadow) { view, val in
                view.shadow(
                    color: Color(semanticColor: val.color) ?? Color(.sRGBLinear, white: 0, opacity: 0.33),
                    radius: val.radius,
                    x: val.x,
                    y: val.y)
            }
    }

    func applyBorderStyle(_ style: AppcuesStyle) -> some View {
        self
            .ifLet(style.borderColor, style.borderWidth) { view, val1, val2 in
                view.overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius ?? 0)
                        .stroke(val1, lineWidth: val2)
                )
            }
    }

    func applyExternalLayout(_ layout: AppcuesLayout) -> some View {
        self
            .padding(layout.margin)
    }

    func applyAllAppcues(_ layout: AppcuesLayout, _ style: AppcuesStyle) -> some View {
        self
            .applyForegroundStyle(style)
            .applyInternalLayout(layout)
            .applyBackgroundStyle(style)
            .applyBorderStyle(style)
            .applyExternalLayout(layout)
    }
}

extension Text {
    func applyTextStyle(_ style: AppcuesStyle) -> some View {
        self
            .ifLet(style.letterSpacing) { view, val in
                view.kerning(val)
            }
            .ifLet(style.textAlignment) { view, val in
                view.multilineTextAlignment(val)
            }
    }
}
