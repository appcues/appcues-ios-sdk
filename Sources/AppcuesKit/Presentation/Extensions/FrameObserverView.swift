//
//  FrameObserverView.swift
//  AppcuesKit
//
//  Created by Matt on 2023-03-20.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal class FrameObserverView: UIView {
    private var oldBounds: CGRect = .zero
    var onChange: ((_ bounds: CGRect) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        if oldBounds != bounds {
            onChange?(bounds)
        }
        oldBounds = bounds
    }
}
