//
//  View+Appcues.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
extension View {
    func setupActions(on viewModel: ExperienceStepViewModel, for componentModel: ComponentModel) -> some View {
        let actions = viewModel.actions(for: componentModel.id)
        // simultaneousGesture is needed to make a Button support any of these gestures.
        return self
            .ifLet(actions[.tap]) { view, actionHandlers in
                view.simultaneousGesture(TapGesture().onEnded {
                    viewModel.enqueueActions(actionHandlers, type: "Button Tapped", viewDescription: componentModel.textDescription)
                })
                .accessibilityAction {
                    viewModel.enqueueActions(actionHandlers, type: "Button Activated", viewDescription: componentModel.textDescription)
                }
            }
            .ifLet(actions[.longPress]) { view, actionHandlers in
                view.simultaneousGesture(LongPressGesture().onEnded { _ in
                    viewModel.enqueueActions(actionHandlers, type: "Button Long Pressed", viewDescription: componentModel.textDescription)
                })
            }
    }

    func applyAllAppcues(_ style: AppcuesStyle) -> some View {
        modifier(AppcuesAllStylesModifier(style: style))
    }
}

@available(iOS 13.0, *)
internal struct AppcuesForegroundStyleModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        content
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
}

@available(iOS 13.0, *)
internal struct AppcuesInternalLayoutModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        content
            .padding(style.padding)
            .frame(width: style.width, height: style.height)
            .if(style.fillWidth) { view in
                view.frame(maxWidth: .infinity)
            }
            // this negative inset reserves space that will later be used to apply
            // any border within the allocated frame size - only applies when a fixed
            // sized frame is being used
            .padding(style.borderInset * -1)
    }
}

@available(iOS 13.0, *)
internal struct AppcuesBackgroundStyleModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        content
            // Order for the backgrounds matters. Images > Gradients > Color.
            .ifLet(style.backgroundImage) { view, val in
                let model = ExperienceComponent.ImageModel(from: val)
                let backgroundAlignment = Alignment(
                    vertical: val.verticalAlignment,
                    horizontal: val.horizontalAlignment
                ) ?? .center
                let backgroundImage = AppcuesImage(model: model)

                if #available(iOS 14.0, *) {
                    view.background(backgroundImage.ignoresSafeArea(.container, edges: .all), alignment: backgroundAlignment).clipped()
                } else {
                    view.background(backgroundImage.edgesIgnoringSafeArea(.all), alignment: backgroundAlignment).clipped()
                }
            }
            .ifLet(style.backgroundGradient) { view, val in
                if #available(iOS 14.0, *) {
                    view.background(val.ignoresSafeArea(.container, edges: .all))
                } else {
                    view.background(val.edgesIgnoringSafeArea(.all))
                }
            }
            .ifLet(style.backgroundColor) { view, val in
                if #available(iOS 14.0, *) {
                    view.background(val.ignoresSafeArea(.container, edges: .all))
                } else {
                    view.background(val.edgesIgnoringSafeArea(.all))
                }
            }
    }
}

@available(iOS 13.0, *)
internal struct AppcuesBorderStyleModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        content
            .ifLet(style.borderColor, style.borderWidth) { view, color, width in
                view
                    // The border should account for space in the layout, not just be an overlay.
                    .padding(width)
                    .overlay(
                        // Note that the `cornerRadius` here is really only needed for the *inner* edge of the border.
                        // The `cornerRadius` modifier a few lines below in this function takes care of rounding off
                        // the *outer* edge appropriately (which is why a cornerRadius of 0 here is ok).
                        // Need to adjust the corner radius to match the radius applied to the view.
                        RoundedRectangle(cornerRadius: max(0, (style.cornerRadius ?? 0) - width / 2))
                            .stroke(color, lineWidth: width)
                            // The RoundedRectangle overlay is added centered on the edge of the view, so
                            // half of the width is outside the view bounds. Add padding for that to
                            // ensure the border never gets half cropped out.
                            .padding(width / 2)
                    )
            }
    }
}

@available(iOS 13.0, *)
internal struct AppcuesCornerRadiusModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        content
            .ifLet(style.cornerRadius) { view, val in
                view.cornerRadius(val)
            }
    }
}

@available(iOS 13.0, *)
internal struct AppcuesShadowModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        content
            .ifLet(style.shadow) { view, val in
                view.shadow(
                    color: Color(dynamicColor: val.color) ?? Color(.sRGBLinear, white: 0, opacity: 0.33),
                    radius: val.radius,
                    x: val.x,
                    y: val.y
                )
            }
    }
}

@available(iOS 13.0, *)
internal struct AppcuesExternalLayoutModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        content
            .padding(style.margin)
    }
}

@available(iOS 13.0, *)
internal struct AppcuesAllStylesModifier: ViewModifier {
    let style: AppcuesStyle

    func body(content: Content) -> some View {
        // Using `AnyView` here drastically improves memory and CPU usage
        AnyView(
            content
                .modifier(AppcuesForegroundStyleModifier(style: style))
                .modifier(AppcuesInternalLayoutModifier(style: style))
                .modifier(AppcuesBorderStyleModifier(style: style))
                .modifier(AppcuesBackgroundStyleModifier(style: style))
                .modifier(AppcuesCornerRadiusModifier(style: style)) // needs to be after border and background
                .modifier(AppcuesShadowModifier(style: style))
                .modifier(AppcuesExternalLayoutModifier(style: style))
        )
    }
}

@available(iOS 13.0, *)
extension Text {
    func applyTextStyle(_ style: AppcuesStyle, model: ExperienceComponent.TextModel) -> some View {
        self
            .ifLet(style.letterSpacing) { view, val in
                view.kerning(val)
            }
            .ifLet(style.textAlignment) { view, val in
                view.multilineTextAlignment(val)
            }
            // The following two lines allow text to scale down in cases where it is too
            // large to fit in the bounds available, and otherwise unnatural clipping
            // or wrapping would occur. For example, a large emoji in a side-by-side layout.
            // SwiftUI requires a line limit to be set for the minimumScaleFactor to be applied,
            // and it must be set to 1 line in the case of a single large character for scaling
            // to be applied.
            .lineLimit(model.text.count == 1 ? 1 : Int.max)
            // Allow scaling down to a minimum of 10pt font, from the original size, to try to fit.
            .minimumScaleFactor(min(10.0 / (model.style?.fontSize ?? UIFont.labelFontSize), 1.0))
    }
}
