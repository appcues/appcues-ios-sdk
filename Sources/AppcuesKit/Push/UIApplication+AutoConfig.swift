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
        guard let appDelegate = UIApplication.shared.delegate else { return }

        swizzle(
            appDelegate,
            targetSelector: NSSelectorFromString("application:didRegisterForRemoteNotificationsWithDeviceToken:"),
            placeholderSelector: #selector(appcues__placeholderApplicationDidRegisterForRemoteNotificationsWithDeviceToken),
            swizzleSelector: #selector(appcues__applicationDidRegisterForRemoteNotificationsWithDeviceToken)
        )
    }

    private static func swizzle(
        _ delegate: UIApplicationDelegate,
        targetSelector: Selector,
        placeholderSelector: Selector,
        swizzleSelector: Selector
    ) {
        // see if the currently assigned delegate has an implementation for the target selector already.
        // these are optional methods in the protocol, and if they are not there already, we'll need to add
        // a placeholder implementation so that we can consistently swap it with our override, which will attempt
        // to call back into it, in case there was an implementation already - if we don't do this, we'll
        // get invalid selector errors in these cases.
        let originalMethod = class_getInstanceMethod(type(of: delegate), targetSelector)

        if originalMethod == nil {
            // this is the case where the existing delegate does not have an implementation for the target selector

            guard let placeholderMethod = class_getInstanceMethod(UIApplication.self, placeholderSelector) else {
                // this really shouldn't ever be nil, as that would mean the function defined a few lines below is no
                // longer there, but we must nil check this call
                return
            }

            // add the placeholder, so it can be swizzled uniformly
            class_addMethod(
                type(of: delegate),
                targetSelector,
                method_getImplementation(placeholderMethod),
                method_getTypeEncoding(placeholderMethod)
            )
        }

        // swizzle the new implementation to inject our own custom logic

        // this should never be nil, as it would mean the function defined a few lines below is no longer there,
        // but we must nil check this call.
        guard let swizzleMethod = class_getInstanceMethod(UIApplication.self, swizzleSelector) else { return }

        // add the swizzled version - this will only succeed once for this instance, if its already there, we've already
        // swizzled, and we can exit early in the next guard
        let addMethodResult = class_addMethod(
            type(of: delegate),
            swizzleSelector,
            method_getImplementation(swizzleMethod),
            method_getTypeEncoding(swizzleMethod)
        )

        guard addMethodResult,
              let originalMethod = originalMethod ?? class_getInstanceMethod(type(of: delegate), targetSelector),
              let swizzledMethod = class_getInstanceMethod(type(of: delegate), swizzleSelector) else {
            return
        }

        // finally, here is where we swizzle in our custom implementation
        method_exchangeImplementations(originalMethod, swizzledMethod)
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
        AppcuesUNUserNotificationCenterDelegate.shared.didRegister(deviceToken: deviceToken)

        // Also call the original implementation
        appcues__applicationDidRegisterForRemoteNotificationsWithDeviceToken(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)

    }
}
