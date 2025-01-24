//
//  Swizzler.swift
//  AppcuesKit
//
//  Created by Matt on 2024-04-11.
//  Copyright © 2024 Appcues. All rights reserved.
//

import Foundation

internal enum Swizzler {
    /// Swizzling for delegate objects.
    ///
    /// This is unique because,
    /// 1. We aren't certain of the class type that implements the delegate protocol at compile time.
    /// This is the reason why this function takes an instance of the delegate instead of the delegate type.
    /// 2. Delegate methods are frequently optional, so we can't rely on the implementation being there to swizzle.
    /// If this is the case, we add an empty placeholder implementation and then swizzle that.
    ///
    /// - Parameters:
    ///   - targetInstance: Instance of the class to replace the method in.
    ///   - targetSelector: Selector of the method to replace.
    ///   - replacementOwner: Class containing the methods selected by `swizzleSelector` and `placeholderSelector`.
    ///   - placeholderSelector: Selector of the method to use the `targetSelector` method is not implemented.
    ///   This should be an empty function.
    ///   - swizzleSelector: Selector of the method to use as the replacement.
    static func swizzle(
        targetInstance: AnyObject,
        targetSelector: Selector,
        replacementOwner: AnyClass,
        placeholderSelector: Selector,
        swizzleSelector: Selector
    ) {
        // see if the currently assigned delegate has an implementation for the target selector already.
        // these are optional methods in the protocol, and if they are not there already, we'll need to add
        // a placeholder implementation so that we can consistently swap it with our override, which will attempt
        // to call back into it, in case there was an implementation already - if we don't do this, we'll
        // get invalid selector errors in these cases.
        let targetClass: AnyClass = type(of: targetInstance)
        let originalMethod = class_getInstanceMethod(targetClass, targetSelector)

        if originalMethod == nil {
            // this is the case where the existing delegate does not have an implementation for the target selector

            guard let placeholderMethod = class_getInstanceMethod(replacementOwner, placeholderSelector) else {
                // this should never be nil as it would be a developer error, but we must nil check this call
                return
            }

            // add the placeholder, so it can be swizzled uniformly
            class_addMethod(
                targetClass,
                targetSelector,
                method_getImplementation(placeholderMethod),
                method_getTypeEncoding(placeholderMethod)
            )
        }

        // this should never be nil since the method gets added above
        guard let originalMethod = originalMethod ?? class_getInstanceMethod(targetClass, targetSelector) else { return }

        // swizzle the new implementation to inject our own custom logic

        // this should never be nil as it would be a developer error, but we must nil check this call
        guard let swizzleMethod = class_getInstanceMethod(replacementOwner, swizzleSelector) else { return }

        // implementations must be different (otherwise the target selector already has the implementation we want) and
        // without this check we would add the implementation again which will cause an infinite loop
        guard method_getImplementation(originalMethod) != method_getImplementation(swizzleMethod) else { return }

        // add the swizzled version - this will only succeed once for this instance, if its already there, we've already
        // swizzled, and we can exit early in the next guard
        let addMethodResult = class_addMethod(
            targetClass,
            swizzleSelector,
            method_getImplementation(swizzleMethod),
            method_getTypeEncoding(swizzleMethod)
        )

        guard addMethodResult,
              let swizzledMethod = class_getInstanceMethod(targetClass, swizzleSelector) else {
            return
        }

        // finally, here is where we swizzle in our custom implementation
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
