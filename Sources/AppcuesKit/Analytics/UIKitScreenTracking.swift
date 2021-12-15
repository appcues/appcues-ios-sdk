//
//  UIKitScreenTracking.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/29/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import UIKit

internal class UIKitScreenTracking {

    // used to ignore SDK presented screens (experiences we create) for the purpose
    // of automatic screen tracking
    internal static var untrackedScreenKey: UInt8 = 0

    private var lastTrackedScreen: String?

    private let publisher: AnalyticsPublisher

    init(container: DIContainer) {
        self.publisher = container.resolve(AnalyticsPublisher.self)

        func swizzle(forClass: AnyClass, original: Selector, new: Selector) {
            guard let originalMethod = class_getInstanceMethod(forClass, original) else { return }
            guard let swizzledMethod = class_getInstanceMethod(forClass, new) else { return }
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }

        swizzle(forClass: UIViewController.self,
                original: #selector(UIViewController.viewDidAppear(_:)),
                new: #selector(UIViewController.appcues__viewDidAppear)
        )

        NotificationCenter.appcues.addObserver(self, selector: #selector(screenTracked), name: .appcuesTrackedScreen, object: nil)
    }

    @objc
    private func screenTracked(notification: Notification) {
        let title: String? = notification.value()
        guard let title = title, lastTrackedScreen != title else { return }

        lastTrackedScreen = title
        publisher.screen(title: title, properties: nil, sync: true)
    }
}
