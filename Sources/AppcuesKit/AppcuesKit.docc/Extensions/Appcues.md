# ``AppcuesKit/Appcues``

## Topics

### Initializing

- ``Appcues/Config``
- ``Appcues/init(config:)``

### Managing Users

- <doc:Identifying>
- ``Appcues/identify(userID:properties:)``
- ``Appcues/anonymous()``
- ``Appcues/group(groupID:properties:)``
- ``Appcues/reset()``

### Tracking Screens and Events

- <doc:Tracking>
- ``Appcues/track(name:properties:)``
- ``Appcues/screen(title:properties:)``
- ``Appcues/trackScreens()``

### Showing Experiences

- ``Appcues/show(experienceID:completion:)``

### Embeds

- ``Appcues/register(frameID:for:on:)``

### Push Notifications

- <doc:PushNotificationsRich>
- <doc:PushNotificationsDebugging>
- <doc:PushNotificationsManually>
- ``Appcues/enableAutomaticPushConfig()``
- ``Appcues/setPushToken(_:)``
- ``Appcues/didReceiveNotification(response:completionHandler:)``

### Debugging

- <doc:Debugging>
- ``Appcues/debug()``
- ``Appcues/filterAndHandle(_:)``
- ``Appcues/didHandleURL(_:)``
- <doc:Logging>

### Customizing and Extending

- ``Appcues/presentationDelegate``
- ``Appcues/experienceDelegate``
- ``Appcues/analyticsDelegate``
- ``Appcues/navigationDelegate``
- ``Appcues/elementTargeting``

### Checking Versions

- ``Appcues/version()-swift.method``
- ``Appcues/version()-swift.type.method`` 
