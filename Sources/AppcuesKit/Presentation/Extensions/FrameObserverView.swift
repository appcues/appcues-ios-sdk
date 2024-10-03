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

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if oldBounds != bounds {
            onChange?(bounds)
        }
        oldBounds = bounds
    }
}
