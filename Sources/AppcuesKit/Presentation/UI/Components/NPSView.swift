//
//  NPSView.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/24/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

// The NPSView is a specialized display format for the AppcuesOptionSelect component.
// It can be used for single-select models. It splits the given set of options in half
// and renders in a specific two row display format, for the net promotor score use case.
@available(iOS 13.0, *)
internal struct NPSView: View {
    let model: ExperienceComponent.OptionSelectModel

    @EnvironmentObject var stepState: ExperienceData.StepState

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // It is expected to have 11 options for NPS: 0-10
            // A bit more flexibility here though to just split the given options
            // in half, taking the ceiling of an odd numbered set - which
            // gives 6 on the first row and 5 on the second row, in the normal display
            let options = stepState.formOptions(for: model.id)
            let rows = options.chunked(into: (options.count + 1) / 2)
            ForEach(rows.indices, id: \.self) { rowIndex in
                // Each row lays out items horizontally, with spacing defined within the model
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex]) { option in
                        let binding = stepState.formBinding(for: model.id, value: option.value)
                        Group {
                            if binding.wrappedValue {
                                (option.selectedContent ?? option.content).view
                            } else {
                                option.content.view
                            }
                        }
                        .onTapGesture { binding.wrappedValue.toggle() }
                    }
                }
            }
        }
    }
}
