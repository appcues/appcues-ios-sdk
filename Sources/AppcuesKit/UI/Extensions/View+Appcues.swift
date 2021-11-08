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
        return self
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
            .padding(layout.margin)
    }
}
