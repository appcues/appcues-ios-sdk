//
//  TooltipWrapperView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-12-19.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class TooltipWrapperView: ExperienceWrapperView {

    var targetRectangle: CGRect? {
        didSet { positionContentWrapperView() }
    }

    private var activeConstraints: [NSLayoutConstraint] = []

    override func positionContentWrapperView() {
        NSLayoutConstraint.deactivate(activeConstraints)

        if let targetRectangle = targetRectangle {
            activeConstraints = [
                contentWrapperView.topAnchor.constraint(equalTo: topAnchor, constant: targetRectangle.maxY + 20),
                contentWrapperView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
                contentWrapperView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),

                // ensure the dialog can't exceed the container height (it should scroll instead).
                contentWrapperView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor),
                contentWrapperView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor)
            ]
        } else {
            // default to a bottom anchored sheet
            activeConstraints = [
                // general position
                contentWrapperView.bottomAnchor.constraint(equalTo: bottomAnchor),
                contentWrapperView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
                contentWrapperView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor),

                // ensure the dialog can't exceed the container height (it should scroll instead).
                contentWrapperView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor)
            ]
        }

        NSLayoutConstraint.activate(activeConstraints)
    }
}
