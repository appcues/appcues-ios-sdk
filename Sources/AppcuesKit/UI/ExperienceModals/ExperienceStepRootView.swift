//
//  ExperienceStepRootView.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-05.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct ExperienceStepRootView<Content: View>: View {
    let rootView: Content

    @ObservedObject var viewModel: ExperienceStepViewModel

    var body: some View {
        rootView
            .environmentObject(viewModel)
    }
}
