//
//  EqualWidthStack.swift
//  AppcuesKit
//
//  Created by Matt on 2022-10-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
private struct StackWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // no-op since there's only a single value
    }
}

@available(iOS 13.0, *)
internal struct EqualWidthStack<Content: View>: View {
    @State private var stackWidth: CGFloat = 0

    let alignment: VerticalAlignment
    let spacing: CGFloat
    let itemCount: Int

    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            Group {
                content
            }
            // maxWidth instead of width to allow the width to shrink after a resize or rotation.
            .frame(maxWidth: stackWidth / CGFloat(itemCount))
            // Ensure the context never escapes the designated frame.
            .clipped()
        }
        // Force a width so that it's not zero for the initial calculation.
        .frame(maxWidth: .infinity)
        // Attach GeometryReader to the background rather than wrapping the HStack to avoid the
        // undesired behavior where the GeometryReader takes all available space.
        .background(GeometryReader { geometry in
            // GeometryReader can't modify the @State value directly because modifying the state
            // during view update causes undefined behavior. Instead, use a PreferenceKey.
            Color.clear
                .preference(key: StackWidthPreferenceKey.self, value: geometry.size.width)
        })
        .onPreferenceChange(StackWidthPreferenceKey.self) {
            // Set the width for another next layout pass.
            stackWidth = $0
        }
    }
}
