//
//  AppcuesTargetView.swift
//  AppcuesKit
//
//  Created by Matt on 2023-05-29.
//  Copyright © 2023 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct ACTagView: UIViewRepresentable {
    let identifier: String?

    func makeUIView(context: Context) -> UIView {
        return AppcuesTargetView(identifier: identifier)
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}

internal class AppcuesTargetView: UIView {

    let appcuesID: String?

    init(identifier: String?) {
        appcuesID = identifier

        super.init(frame: .zero)

        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
