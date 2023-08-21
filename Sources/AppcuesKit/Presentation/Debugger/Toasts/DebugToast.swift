//
//  DebugToast.swift
//  AppcuesKit
//
//  Created by Matt on 2023-08-15.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal struct DebugToast {
    enum Style {
        case success
        case failure
    }

    enum Message {
        case screenCaptureSuccess(displayName: String)
        case screenCaptureFailure
        case screenUploadFailure
        case custom(text: String)
    }

    let message: Message
    let style: Style
    let duration: TimeInterval
    let retryAction: (() -> Void)?

    init(message: Message, style: DebugToast.Style, duration: TimeInterval = 3.0, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.style = style
        self.duration = duration
        self.retryAction = retryAction
    }
}
