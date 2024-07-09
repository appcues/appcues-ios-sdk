# Configuring Rich Push Notifications

Rich push notifications are push notifications that include images. Rich push notifications require a Notification Service Extension which modifies the push payload before it's displayed.

## Step 1. Create a Notification Service Extension

In Xcode, navigate to **File → New → Target** and select Notification Service Extension.

Ensure that your main app target is selected in the Embed In Application dropdown.

## Step 2. Install the Appcues Notification Service

The Appcues Notification Service library modifies the payload for Appcues push notifications. It can be installed with Swift Package Manager or Cocoapods.

### Swift Package Manager (SPM)

Add the Swift package as a dependency to your project in Xcode:

1. In Xcode, open your project and navigate to **File → Add Packages…**
2. Enter the package URL https://github.com/appcues/appcues-ios-sdk
3. For **Dependency Rule**, select **Up to Next Major Version**
4. Click **Add Package**
5. In the **Choose Package Products** modal, choose your Notification Service Extension as the target for the Appcues Notification Service library
6. Click **Add Package**

### Cocoapods

1. Update your Podfile to include your new Notification Service Extension and the Appcues Notification Service
    ```rb
    target '<YOUR_NOTIFICATION_EXTENSION_TARGET>' do
        pod 'AppcuesNotificationService'
    end
    ```
2. In Terminal, run
    ```
    pod install
    ```

## Step 3. Use the Appcues Notification Service

Replace the contents of the Xcode template-generated `NotificationService.swift`.

```diff
+ import AppcuesNotificationService

+ class NotificationService: AppcuesNotificationServiceExtension {}
- class NotificationService: UNNotificationServiceExtension {
-     ...
- }
```

## Step 4: Update the Apple Developer Portal

A Notification Service Extension is a separate binary that's bundled with your app. It must be set up in the Apple Developer Portal with its own app ID and provisioning profile.
