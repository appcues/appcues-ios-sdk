//
//  PagerViewModifier.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

/// Wrap the iOS 14+ functionality. We'll need a custom iOS 13 compatible version of this.
internal struct PagerViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
        } else {
            content
        }
    }
}
