# Configuring Handling of Universal Links

The Appcues iOS SDK supports universal links as an option for deep linking to screens within your app.

## Overview

You must implement `UIApplicationDelegate.application(_:continue:restorationHandler:)` to handle your universal links. By default, the Appcues iOS SDK will call this method for every `https` link it tries to open to allow your app a chance to handle it internally instead of opening the link in a browser. Optionally, you may provide an allow list of URL hosts—refer to the Domain Allow List section below.

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

## Implementing a Domain Allow List 

You may define a custom key, `AppcuesUniversalLinkHostAllowList`, in your _Info.plist_ file with an array of (string) host values to control which URLs are passed to `UIApplicationDelegate.application(_:continue:restorationHandler:)`. A URL whose host matches any of the provided host values will be treated as a potential universal link.

An empty array will prevent all links from be treated as universal links and is functionally the same as calling ``Appcues/Config/enableUniversalLinks(_:)`` with a `false` argument.

If the `AppcuesUniversalLinkHostAllowList` key is absent from `Info.plist`, all `https` links will be treated as potential universal links.

Example _Info.plist_ to only treat links to `appcues.com` as universal links:

```plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    ...
    <key>AppcuesUniversalLinkHostAllowList</key>
    <array>
        <string>appcues.com</string>
    </array>
</dict>
</plist>
```
