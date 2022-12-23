//
//  UIViewController+Tracking.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/25/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

extension Notification.Name {
    internal static let appcuesTrackedScreen = Notification.Name("appcuesTrackedScreen")
    internal static let appcuesTemplateCapture = Notification.Name("appcuesTemplateCapture")
    internal static let appcuesTemplatePreview = Notification.Name("appcuesTemplatePreview")
    internal static let appcuesTemplateClone = Notification.Name("appcuesTemplateClone")
    internal static let appcuesInteractionEvent = Notification.Name("appcuesInteractionEvent")
}

extension Notification {

    static func toInfo<T>(_ value: T) -> [String: T] { return ["key": value] }

    func value<T>() -> T? {

        guard let info = self.userInfo as? [String: T],
            let oper = info["key"] else {
            return nil
        }

        return oper
    }
}

extension UIViewController {

    internal func captureScreen() {
        guard let top = UIApplication.shared.topViewController() else { return }

        // this untracked flag allows us to avoid tracking screens that our SDK presented
        let untracked = objc_getAssociatedObject(self, &UIKitScreenTracker.untrackedScreenKey) as? Bool ?? false
        guard !untracked else { return }

        var name = String(describing: top.self.classForCoder)
        if name != "ViewController" {
            name = name.replacingOccurrences(of: "ViewController", with: "")
        }

        // communicate the tracked screen back to AnalyticsTracker
        NotificationCenter.appcues.post(name: .appcuesTrackedScreen,
                                        object: self,
                                        userInfo: Notification.toInfo(name))
    }

    @objc
    internal func appcues__viewDidAppear(animated: Bool) {
        captureScreen()
        // this is calling the original implementation of viewDidAppear since it has been swizzled
        appcues__viewDidAppear(animated: animated)
    }
}
