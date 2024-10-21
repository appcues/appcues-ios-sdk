//
//  FrameObserverView.swift
//  AppcuesKit
//
//  Created by Matt on 2023-03-20.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class FrameObserverView: UIView {
    private var oldBounds: CGRect = .zero
    var onChange: (@MainActor (_ bounds: CGRect) async -> Void)?

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
            Task { @MainActor in
                await onChange?(bounds)
            }
        }
        oldBounds = bounds
    }
}
