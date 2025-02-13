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

    // tracks whether our swizzled scroll handlers have been activated yet,
    // allows for delaying this until only when actually needed, and only doing once
    private var initialized = false

    // Using a simple approach here where a single StepRecoverObserver can be attached at a time.
    //
    // This could have been a more sophisticated list of weak references to some Protocol implementation,
    // but that would seem to add unnecessary complexity and list management, when really only a single
    // RenderContext in the application (the modal context) can be in recovery mode at any given time.
    private weak var observer: StepRecoveryObserver?

    func attach(using observer: StepRecoveryObserver) {
        if !initialized {
            initialized = true
            UIScrollView.swizzleScrollViewGetDelegate()
        }
        self.observer = observer
    }

    func detach() {
        self.observer = nil
    }

    // if any scroll activity is currently active, cancel any pending scrollEnded notifications
    // and wait for the next scroll completion to attempt any retry
    func didBeginDragging() {
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
                guard let self = self else { return }
                // the observer may have been made `nil` in the 1 second delay, so
                // we use the current state and do not send the notification if it
                // is no longer listening for retry
                self.observer?.scrollEnded()
                self.retryWorkItem = nil
            }
            self.retryWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
        }
    }

    // MARK: UIScrollViewDelegate
    // these are called by scroll views that don't have an assigned delegate that needs to be swizzled.

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        AppcuesScrollViewDelegate.shared.didBeginDragging()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        AppcuesScrollViewDelegate.shared.scrollEnded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            AppcuesScrollViewDelegate.shared.scrollEnded()
        }
    }
}

@available(iOS 13.0, *)
extension UIScrollView {
    
    // this set includes `AppcuesScrollViewDelegate.shared` by default since it doesn't need to be swizzled
    private static var swizzledClasses: Set<String> = ["\(type(of: AppcuesScrollViewDelegate.shared))"]

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

        // this call looks recursive, but it is not, it is calling the swapped implementation
        // to get the actual delegate value that has been assigned, if any - can be nil
        if let existingDelegate = appcues__getScrollViewDelegate() {
            delegate = existingDelegate

            let type = "\(type(of: existingDelegate))"
            if !UIScrollView.swizzledClasses.contains(type) {
                UIScrollView.swizzledClasses.insert(type)

                Swizzler.swizzle(
                    targetInstance: delegate,
                    targetSelector: NSSelectorFromString("scrollViewWillBeginDragging:"),
                    replacementOwner: UIScrollView.self,
                    placeholderSelector: #selector(appcues__placeholderScrollViewWillBeginDragging),
                    swizzleSelector: #selector(appcues__scrollViewWillBeginDragging)
                )

                Swizzler.swizzle(
                    targetInstance: delegate,
                    targetSelector: NSSelectorFromString("scrollViewDidEndDecelerating:"),
                    replacementOwner: UIScrollView.self,
                    placeholderSelector: #selector(appcues__placeholderScrollViewDidEndDecelerating),
                    swizzleSelector: #selector(appcues__scrollViewDidEndDecelerating)
                )

                Swizzler.swizzle(
                    targetInstance: delegate,
                    targetSelector: NSSelectorFromString("scrollViewDidEndDragging:willDecelerate:"),
                    replacementOwner: UIScrollView.self,
                    placeholderSelector: #selector(appcues__placeholderScrollViewDidEndDragging),
                    swizzleSelector: #selector(appcues__scrollViewDidEndDragging)
                )
            }
        } else {
            // if it is nil, then we assign our own delegate implementation so there is
            // something hooked in to listen to scroll
            delegate = AppcuesScrollViewDelegate.shared

            // If we need to set a non-nil implementation where there previously was not one,
            // swap the swizzled getter back first, then assign, then restore the swizzled getter.
            // This is done to avoid infinite recursion in some cases observed, where a UICollectionView,
            // for example, may call the getter during the execution of the setter.
            UIScrollView.swizzleScrollViewGetDelegate()
            self.delegate = delegate
            UIScrollView.swizzleScrollViewGetDelegate()
        }

        return delegate
    }

    @objc
    func appcues__placeholderScrollViewWillBeginDragging(_ scrollView: UIScrollView) {
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
    func appcues__scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if responds(to: #selector(appcues__scrollViewWillBeginDragging(_:))) {
            appcues__scrollViewWillBeginDragging(scrollView)
        }

        AppcuesScrollViewDelegate.shared.didBeginDragging()
    }

    @objc
    func appcues__scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if responds(to: #selector(appcues__scrollViewDidEndDecelerating(_:))) {
            appcues__scrollViewDidEndDecelerating(scrollView)
        }

        AppcuesScrollViewDelegate.shared.scrollEnded()
    }

    @objc
    func appcues__scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if responds(to: #selector(appcues__scrollViewDidEndDragging(_:willDecelerate:))) {
            appcues__scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        }

        if !decelerate {
            AppcuesScrollViewDelegate.shared.scrollEnded()
        }
    }
}
