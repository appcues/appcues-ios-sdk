# Configuring Push Notifications

The Appcues iOS SDK supports receiving push notification so you can reach your users whenever the moment is right.

There are two options for configuring push notification: automatic or manual.

> Tip: Automatic configuration is the quickest and simplest way to configure push notifications and is recommended for most customers. Refer to <doc:PushNotificationsManually> for manual configuration instructions.

## Prerequisites

It is recommended to have [configured your iOS push settings in Appcues Studio](https://docs.appcues.com/en_US/push-notifications/push-notification-settings) before configuring push notifications in your app to allow you quickly test your configuration end to end.

## Enabling Push Notification Capabilities

In Xcode, navigate to the Signing & Capabilities section of your main app target and add the Push Notifications capability.

## Automatic App Configuration

Automatic configuration takes advantage of swizzling to automatically provide the necessary implementations of the required `UIApplicationDelegate` and `UNUserNotificationCenterDelegate` methods.

To enable automatic configuration, call ``Appcues/enableAutomaticPushConfig()`` from `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)`.

```swift
// AppDelegate.swift

func application(
    _ application: UIApplication, didFinishLaunchingWithOptions
    launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    // Automatically configure for push notifications
    Appcues.enableAutomaticPushConfig()

    // Override point for customization after application launch.
}
```

Automatic configuration works alongside any pre-existing push notification handling in your app by handling only notifications from Appcues while calling any pre-existing handling for non-Appcues notifications.

## Supporting Rich Media

Refer to <doc:PushNotificationsRich>.

## Testing Push Configuration

Refer to <doc:PushNotificationsDebugging>.
