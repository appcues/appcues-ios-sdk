# Configuring the Appcues URL Scheme

The Appcues iOS SDK includes support for a custom URL scheme that supports previewing Appcues experiences in-app prior to publishing and launching the Appcues debugger.

## Overview

Configuring the Appcues URL scheme involves adding a `CFBundleURLTypes` value and then directing the incoming URL to the Appcues iOS SDK.

> It is **strongly** recommended that you configure the custom URL scheme. It allows non-developer users of your Appcues instance to test Appcues experiences in a real setting. It's also valuable for future troubleshooting and support from Appcues via the debugger.

## Register the Custom URL Scheme

Update your `Info.plist` to register the custom URL scheme. Replace `APPCUES_APPLICATION_ID` in the snippet below with your app's Appcues Application ID. This value can be obtained from your [Appcues settings](https://studio.appcues.com/settings/installation).

For example, if your Appcues Application ID is `123-xyz` your url scheme value would be `appcues-123-xyz`.

```
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>appcues-APPCUES_APPLICATION_ID</string>
        </array>
    </dict>
</array>
```

## Handle the Custom URL Scheme

Custom URL's should be handled with a call to ``Appcues/filterAndHandle(_:)`` or ``Appcues/didHandleURL(_:)``. If the URL being opened is an Appcues URL, the URL will be handled.

If your app uses a Scene delegate, add the following:

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // Handle Appcues deeplinks.
    let unhandledURLContexts = appcues.filterAndHandle(connectionOptions.urlContexts)

    // Handle any links remaining in unhandledURLContexts.
}

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    // Handle Appcues deeplinks.
    let unhandledURLContexts = appcues.filterAndHandle(URLContexts)

    // Handle any links remaining in unhandledURLContexts.
}
```

If your app uses only an App delegate, add the following:

```swift
func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
    // Handle Appcues deeplinks.
    guard !appcues.didHandleURL(url) else { return true }

    // Handle a non-Appcues URL.
    return false
}
```

A SwiftUI app can handle the custom URL scheme as part of the `onOpenURL` modifier associated with the `Scene` of your main `App`:

```swift
var body: some Scene {
    WindowGroup {
        MyApp()
        .onOpenURL { url in
            guard !appcues.didHandleURL(url) else { return }
        }
    }
}
```

## Verifying the Custom URL Scheme

Test that the URL scheme handling is set up correctly by navigating to `appcues-APPCUES_APPLICATION_ID://debugger` in your browser on the device with the app installed.

See <doc:Debugging> for details on the functionality of the debugger.
