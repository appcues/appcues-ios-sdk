//
//  View+Appcues.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension View {
    // Recursively work through the sequence of actions in series.
    private func process(_ actionHandlers: [(@escaping ActionRegistry.Completion) -> Void]) {
        if let handler = actionHandlers.first {
            handler {
                DispatchQueue.main.async {
                    // On completion, process the remaining action handlers.
                    process(Array(actionHandlers.dropFirst()))
                }
            }
        }
    }

    func setupActions(_ actions: [ExperienceStepViewModel.ActionType: [(@escaping ActionRegistry.Completion) -> Void]]) -> some View {
        // simultaneousGesture is needed to make a Button support any of these gestures.
        self
            .ifLet(actions[.tap]) { view, actionHandlers in
                view.simultaneousGesture(TapGesture().onEnded {
                    process(actionHandlers)
                })
            }
            .ifLet(actions[.longPress]) { view, actionHandlers in
                view.simultaneousGesture(LongPressGesture().onEnded { _ in
                    process(actionHandlers)
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

    func applyInternalLayout(_ style: AppcuesStyle) -> some View {
        self
            .padding(style.padding)
            .frame(width: style.width, height: style.height)
            .if(style.fillWidth) { view in
                view.frame(maxWidth: .infinity)
            }
    }

    func applyBackgroundStyle(_ style: AppcuesStyle) -> some View {
        self
            .ifLet(style.backgroundColor) { view, val in
                if #available(iOS 14.0, *) {
                    view.background(val.ignoresSafeArea(.container, edges: .all))
                } else {
                    view.background(val.edgesIgnoringSafeArea(.all))
                }
            }
            .ifLet(style.backgroundGradient) { view, val in
                if #available(iOS 14.0, *) {
                    view.background(val.ignoresSafeArea(.container, edges: .all))
                } else {
                    view.background(val.edgesIgnoringSafeArea(.all))
                }
            }
            .ifLet(style.cornerRadius) { view, val in
                view.cornerRadius(val)
            }
            .ifLet(style.shadow) { view, val in
                view.shadow(
                    color: Color(dynamicColor: val.color) ?? Color(.sRGBLinear, white: 0, opacity: 0.33),
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

    func applyExternalLayout(_ style: AppcuesStyle) -> some View {
        self
            .padding(style.margin)
    }

    func applyAllAppcues(_ style: AppcuesStyle) -> some View {
        self
            .applyForegroundStyle(style)
            .applyInternalLayout(style)
            .applyBackgroundStyle(style)
            .applyBorderStyle(style)
            .applyExternalLayout(style)
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
