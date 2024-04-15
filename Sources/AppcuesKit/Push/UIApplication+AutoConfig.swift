//
//  UIApplication+AutoConfig.swift
//  AppcuesKit
//
//  Created by Matt on 2024-04-11.
//  Copyright © 2024 Appcues. All rights reserved.
//

import UIKit

extension UIApplication {
    static func swizzleDidRegisterForDeviceToken() {
        guard let appDelegateInstance = UIApplication.shared.delegate else { return }

        Swizzler.swizzle(
            targetInstance: appDelegateInstance,
            targetSelector: NSSelectorFromString("application:didRegisterForRemoteNotificationsWithDeviceToken:"),
            replacementOwner: UIApplication.self,
            placeholderSelector: #selector(appcues__placeholderApplicationDidRegisterForRemoteNotificationsWithDeviceToken),
            swizzleSelector: #selector(appcues__applicationDidRegisterForRemoteNotificationsWithDeviceToken)
        )
    }

    @objc
    func appcues__placeholderApplicationDidRegisterForRemoteNotificationsWithDeviceToken(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // this gives swizzling something to replace, if the existing delegate doesn't already
        // implement this function.
    }

    @objc
    func appcues__applicationDidRegisterForRemoteNotificationsWithDeviceToken(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushAutoConfig.didRegister(deviceToken: deviceToken)

        // Also call the original implementation
        appcues__applicationDidRegisterForRemoteNotificationsWithDeviceToken(
            application,
            didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
        )
    }
}
