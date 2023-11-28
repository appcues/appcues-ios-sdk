//
//  UIScrollView+ScrollObserver.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/27/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

// This class provides a centralized access point for scroll updates, via the static
// shared instance. The UIScrollView swizzled methods below can then send updates
// into this class and have them processed and broadcast to a StepRecoverObserver, if
// any observer is currently in recovery/retry mode (i.e. failed tooltip)
@available(iOS 13.0, *)
internal class AppcuesScrollViewDelegate: NSObject, UIScrollViewDelegate {
    static var shared = AppcuesScrollViewDelegate()

    private var retryWorkItem: DispatchWorkItem?

    // Using a simple approach here where a single StepRecoverObserver can be attached at a time.
    //
    // This could have been a more sophisticated list of weak references to some Protocol implementation,
    // but that would seem to add unnecessary complexity and list management, when really only a single
    // RenderContext in the application (the modal context) can be in recovery mode at any given time.
    weak var observer: StepRecoveryObserver?

    // if any scroll activity is currently active, cancel any pending scrollEnded notifications
    // and wait for the next scroll completion to attempt any retry
    func didScroll() {
        // cancel any existing notification
        retryWorkItem?.cancel()
        retryWorkItem = nil
    }

    // Scroll has to have ended via scrollViewDidEndDragging or scrollViewDidEndDecelerating
    // and come to a rest for 1 second to send the scrollEnded update to our recovery observer.
    // This delay ensures that any bounce effect will settle, or avoid sending excessive updates
    // if scrolling is resumed immediately after it stops.
    func scrollEnded() {
        // only schedule a notification if we have an observer in retry state listening
        guard observer != nil else { return }

        // start a 1 sec timer to notify observer unless more scroll occurs
        if retryWorkItem == nil {
            let workItem = DispatchWorkItem { [weak self] in
                // the observer may have been made `nil` in the 1 second delay, so
                // we use the current state and do not send the notification if it
                // is no longer listening for retry
                self?.observer?.scrollEnded()
            }
            retryWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
        }
    }
}

@available(iOS 13.0, *)
extension UIScrollView {

    static func swizzleScrollViewGetDelegate() {
        // this will swap in a new getter for UIScrollView.delegate - giving our code a chance to hook
        // in and override the scrollViewDidScroll callback and monitor for UI scroll changes that might
        // impact Appcues experience rendering
        let originalScrollViewDelegateSelector = #selector(getter: self.delegate)
        let swizzledScrollViewDelegateSelector = #selector(appcues__getScrollViewDelegate)

        guard let originalScrollViewMethod = class_getInstanceMethod(self, originalScrollViewDelegateSelector),
              let swizzledScrollViewMethod = class_getInstanceMethod(self, swizzledScrollViewDelegateSelector) else {
            return
        }

        method_exchangeImplementations(originalScrollViewMethod, swizzledScrollViewMethod)
    }

    // this is our custom getter logic for the UIScrollView.delegate
    @objc
    private func appcues__getScrollViewDelegate() -> UIScrollViewDelegate? {
        let delegate: UIScrollViewDelegate

        var shouldSetDelegate = false

        // this call looks recursive, but it is not, it is calling the swapped implementation
        // to get the actual delegate value that has been assigned, if any - can be nil
        if let existingDelegate = appcues__getScrollViewDelegate() {
            delegate = existingDelegate
        } else {
            // if it is nil, then we assign our own delegate implementation so there is
            // something hooked in to listen to scroll
            delegate = AppcuesScrollViewDelegate.shared
            shouldSetDelegate = true
        }

        swizzle(
            delegate,
            targetSelector: NSSelectorFromString("scrollViewDidScroll:"),
            placeholderSelector: #selector(appcues__placeholderScrollViewDidScroll),
            swizzleSelector: #selector(appcues__scrollViewDidScroll)
        )

        swizzle(
            delegate,
            targetSelector: NSSelectorFromString("scrollViewDidEndDecelerating:"),
            placeholderSelector: #selector(appcues__placeholderScrollViewDidEndDecelerating),
            swizzleSelector: #selector(appcues__scrollViewDidEndDecelerating)
        )

        swizzle(
            delegate,
            targetSelector: NSSelectorFromString("scrollViewDidEndDragging:willDecelerate:"),
            placeholderSelector: #selector(appcues__placeholderScrollViewDidEndDragging),
            swizzleSelector: #selector(appcues__scrollViewDidEndDragging)
        )

        // If we need to set a non-nil implementation where there previously was not one,
        // swap the swizzled getter back first, then assign, then restore the swizzled getter.
        // This is done to avoid infinite recursion in some cases observed, where a UICollectionView,
        // for example, may call the getter during the execution of the setter.
        if shouldSetDelegate {
            UIScrollView.swizzleScrollViewGetDelegate()
            self.delegate = delegate
            UIScrollView.swizzleScrollViewGetDelegate()
        }

        return delegate
    }

    private func swizzle(
        _ delegate: UIScrollViewDelegate,
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

            guard let placeholderMethod = class_getInstanceMethod(UIScrollView.self, placeholderSelector) else {
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
        guard let swizzleMethod = class_getInstanceMethod(UIScrollView.self, swizzleSelector) else { return }

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
    func appcues__placeholderScrollViewDidScroll(_ scrollView: UIScrollView) {
        // this gives swizzling something to replace, if the existing delegate doesn't already
        // implement this function.
    }

    @objc
    func appcues__placeholderScrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // this gives swizzling something to replace, if the existing delegate doesn't already
        // implement this function.
    }

    @objc
    func appcues__placeholderScrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // this gives swizzling something to replace, if the existing delegate doesn't already
        // implement this function.
    }

    @objc
    func appcues__scrollViewDidScroll(_ scrollView: UIScrollView) {
        appcues__scrollViewDidScroll(scrollView)

        AppcuesScrollViewDelegate.shared.didScroll()
    }

    @objc
    func appcues__scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        appcues__scrollViewDidEndDecelerating(scrollView)

        AppcuesScrollViewDelegate.shared.scrollEnded()
    }

    @objc
    func appcues__scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        appcues__scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)

        if !decelerate {
            AppcuesScrollViewDelegate.shared.scrollEnded()
        }
    }
}
