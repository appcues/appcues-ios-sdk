# Debugging Push Notifications

The Appcues Debugger can validate your push notification setup end-to-end.

Refer to <doc:Debugging> for general details about the Appcues Debugger.

Tap the **Push Notifications Configured** row in the Appcues Debugger to check your configuration and send a test push notification. The test push notification include an image. If you do not see the image, review <doc:PushNotificationsRich>.

### Debugger Error Codes

|Error Code |Fix|
|-----------|---|
|0          |The Appcues SDK could not determine which APNs environment your app is running in. This is likely caused by a missing push capability for your main app target.|
|1          |The Appcues SDK has not received a APNs token. Ensure that 1) you have enabled the push capability for your main app target, 2) `UIApplication.registerForRemoteNotifications()` has been called, and 3) that `UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` has been implemented and calls ``Appcues/setPushToken(_:)``. Review Steps 1, 2, and 3 of <doc:PushNotificationsManually>.|
|2          |Your app has never requested permission to send foreground notifications. For debugging purposes, you can trigger this permission request by retrying the push verification in the Appcues Debugger.|
|3          |You have previously denied permission for the app to send foreground notifications on your device. You must change this in the iOS System Settings for your app.|
|4          |Your push permission status is not authorized. You must change this in the iOS System Settings for your app.|
|5          |`UNUserNotificationCenter.current().delegate` is not assigned. Review <doc:PushNotificationsManually#Step-4-Enable-push-response-handling> of <doc:PushNotificationsManually>.|
|6          |`UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` is not implemented. Review <doc:PushNotificationsManually#Step-4-Enable-push-response-handling> of <doc:PushNotificationsManually>.|
|7          |Your implementation of `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)` is calling the `completionHandler` block too many times. Your implementation should not execute the completion block for Appcues notifications. Review <doc:PushNotificationsManually#Step-4-Enable-push-response-handling> of <doc:PushNotificationsManually>.|
|8          |The Appcues SDK is not receiving the notification response from your implementation of `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:)`. Ensure that you are passing the notification response to ``Appcues/didReceiveNotification(response:completionHandler:)``. Review <doc:PushNotificationsManually#Step-4-Enable-push-response-handling> of <doc:PushNotificationsManually>.|
|9          |You have not implemented `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)`. This method is optional, but it is recommended to define how to handle notifications that arrive while your app is foregrounded. You will not receive the test push from the Appcues Debugger if this method is not implemented. Review <doc:PushNotificationsManually#Step-5-Configure-foreground-handling> of <doc:PushNotificationsManually>.|
|`<3-digit>`|3-digit error codes indicate an error from the server sending a test push and usually are not caused by incorrect configuration of the Appcues SDK. If a server issue is suspected, wait a few minutes and try again or contact Appcues support.|
