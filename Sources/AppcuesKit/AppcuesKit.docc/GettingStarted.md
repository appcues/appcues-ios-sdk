# Getting Started with Appcues iOS SDK

Initialize the SDK and track events.

## Initializing the SDK

An instance of the Appcues iOS SDK (``Appcues``) should be initialized when your app launches. A lifecycle method such as `application(_:didFinishLaunchingWithOptions:)` in would be a common location:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  let appcuesConfig = Appcues.Config(
    accountID: <#APPCUES_ACCOUNT_ID#>,
    applicationID: <#APPCUES_APPLICATION_ID#>)
    
  appcues = Analytics(configuration: configuration)
}
```

The ``Appcues/Config`` object has a number of properties that may optionally be set to customize the behavior of the SDK. 

Initializing the SDK requires you to provide two values, an Appcues account ID, and an Appcues mobile application ID. These values can be obtained from your [Appcues settings](https://studio.appcues.com/settings/account).

## Managing Users

In order to target content to the right users at the right time, you need to identify users and send Appcues data about them. A user is identified with a unique ID.

- ``Appcues/identify(userID:properties:)``

For more detail about session management and anonymous user tracking, refer to <doc:Identifying>.

## Tracking Screens and Events

Events are the “actions” your users take in your application, which can be anything from clicking a certain button to viewing a specific screen. Once you’ve installed and initialized the Appcues iOS SDK, you can start tracking screens and events using the following methods:

- ``Appcues/track(name:properties:)``
- ``Appcues/screen(title:properties:)``

For more detail about tracking screens and events, refer to <doc:Tracking>.

## Debugging

See <doc:Debugging>.
