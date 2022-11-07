# Configuring Handling of Universal Links

The Appcues iOS SDK supports universal links as an option deep linking to screens within your app.

## Overview

You must implement `UIApplicationDelegate.application(_:continue:restorationHandler:)` to handle your universal links. The Appcues iOS SDK will call this method for every `https` link it tries to open to allow your app a chance to handle it internally instead of opening the link in a browser.

> If your app has opted into [UIKit Scenes](https://developer.apple.com/documentation/uikit/app_and_environment/scenes), you still must implement the `UIApplicationDelegate` method to handle universal links triggered from the Appcues iOS SDK.

## Implementing the NSUserActivity Handler

Your implementation of `UIApplicationDelegate.application(_:continue:restorationHandler:)` must return `true` if you've successfully handled the link and `false` otherwise.

If needed, you can identify links coming from the Appcues iOS SDK by a `referrer` property in the `NSUserActivity.userInfo` dictionary.

```swift
// AppDelegate.swift

func application(_ application: UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
{

    // Get URL components from the incoming user activity.
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
        let incomingURL = userActivity.webpageURL else {
        return false
    }

    if userActivity.userInfo?["referrer"] as? String == "Appcues" {
        // This userActivity was trigged from the Appcues iOS SDK.
    }

    // TODO: Parse the `incomingURL` here and return true if the link has been handled, false otherwise.
}
```
