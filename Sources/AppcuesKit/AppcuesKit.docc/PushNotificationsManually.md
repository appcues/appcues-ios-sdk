# Manually Configuring Push Notifications

The Appcues iOS SDK supports receiving push notification so you can reach your users whenever the moment is right.

There are two options for configuring push notification: automatic or manual.

> Tip: Automatic configuration is the quickest and simplest way to configure push notifications and is recommended for most customers. Refer to <doc:PushNotifications> for automatic configuration instructions.

Follow in tutorial form with <doc:PushNotificationsTutorial>.

## Prerequisites

It is recommended to have [configured your iOS push settings in Appcues Studio](https://docs.appcues.com/en_US/push-notifications/push-notification-settings) before configuring push notifications in your app to allow you quickly test your configuration end to end.

## Manual App Configuration

### Step 1. Enable push capabilities

In Xcode, navigate to the Signing & Capabilities section of your main app target and add the Push Notifications capability.

### Step 2. Register for push notifications

```swift
// AppDelegate.swift

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    application.registerForRemoteNotifications()

    // ...
}
```

### Step 3. Set push token for Appcues

Call ``Appcues/setPushToken(_:)`` from `UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` to pass the APNs token from calling `registerForRemoteNotifications()` to Appcues.

```swift
// AppDelegate.swift

func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    appcuesInstance.setPushToken(deviceToken)
}
```

### Step 4. Enable push response handling

Update your `AppDelegate` to conform to the `UNUserNotificationCenterDelegate` protocol and assign `self` the delegate in `application(_:didFinishLaunchingWithOptions:)`.

Implement `userNotificationCenter(_:didReceive:withCompletionHandler:)` and pass the received notification response to ``Appcues/didReceiveNotification(response:)``.

```swift
// AppDelegate.swift

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self

        // ...
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if appcuesInstance.didReceiveNotification(response: response) {
            completionHandler()
            return
        }

        completionHandler()
    }
}
```


### Step 5. Configure foreground handling

Configure handling of push notifications received while your app is in the foreground by implementing `userNotificationCenter(_:willPresent:withCompletionHandler:)`.

```swift
// AppDelegate.swift

func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .list])
}
```
