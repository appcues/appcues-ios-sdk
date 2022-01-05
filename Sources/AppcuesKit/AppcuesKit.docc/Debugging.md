# Previewing and Debugging Appcues Experiences

The Appcues iOS SDK supports previewing Appcues experiences in-app prior to publishing, triggered by a link with a custom URL scheme.

The Appcues debugger is an in-app overlay that provides debug information in an accessible manner.

> It is **strongly** recommended that you configure the custom URL scheme. It allows non-developer users of your Appcues instance to test Appcues experiences in a real setting. It's also valuable for future troubleshooting and support from Appcues via the debugger.

## Configuring Your Custom URL Scheme

### Register the Custom URL Scheme

Update your `Info.plist` to register the custom URL scheme. Replace `APPCUES_APPLICATION_ID` in the snippet below with your app's Appcues Application ID. This value can be obtained from your [Appcues settings](https://studio.appcues.com/settings/account). 

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

### Handle the Custom URL Scheme

Custom URL's should be handled with a call to ``Appcues/didHandleURL(_:)``. If the URL being opened is an Appcues URL, the URL will be handled, and the functionn will return `true`. If the URL is not an Appcues URL, the function will return `false`.

If your app uses a Scene delegate, add the following:

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // Handle Appcues deeplinks.
    appcues.didHandleURL(connectionOptions.urlContexts)
}

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    // Handle Appcues deeplinks.
    guard !appcues.didHandleURL(URLContexts) else { return }
}
```

If your app uses only an App delegate, add the following:

```swift
func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
    // Handle Appcues deeplinks.
    guard !appcues.didHandleURL(url) else { return true }
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

### Verifying the Custom URL Scheme

Test that the URL scheme handling is set up correctly by navigating to `appcues-APPCUES_APPLICATION_ID://debugger` in your browser on the device with the app installed.

## Manually Launching the Debugger

The Appcues debugger can also be manually trigger apart from the custom URL scheme with a call to ``Appcues/debug()``.
