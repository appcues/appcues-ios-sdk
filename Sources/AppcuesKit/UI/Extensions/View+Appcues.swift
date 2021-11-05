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
        // NOTE: The order of the gestures here matters.
        // If doubleTap is added before tap, two tap events will register [tap, doubleTap].
        // If tap is added before doubleTap, two tap events will register [tap, doubleTap, tap].

        // simultaneousGesture is needed to make a Button support any of these gestures.
        return self
            .ifLet(actions[.doubleTap]) { view, actionHandlers in
                view.simultaneousGesture(TapGesture(count: 2).onEnded {
                    actionHandlers.forEach { actionHandler in actionHandler() }
                })
            }
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

    func applyAppcues(_ layout: AppcuesLayout, _ style: AppcuesStyle) -> some View {
        self
            .modifier(layout)
            .modifier(style)
            // margin needs to be added after backgrounds/borders
            .ifLet(layout.margin) { view, val in
                view.padding(val)
            }
    }
}
