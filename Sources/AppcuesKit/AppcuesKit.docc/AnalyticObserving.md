# Observing Analytics

A delegate can be registered to allow for the host application to see all of the analytics that are being tracked by the Appcues iOS SDK.

## Registering the AppcuesAnalyticsDelegate

One of the types in your application can adhere to the ``AppcuesAnalyticsDelegate`` protocol. In the usage example below, this is done with an extension on the `AppDelegate`. This protocol defines a single function ``AppcuesAnalyticsDelegate/didTrack(analytic:value:properties:isInternal:)``, which provides access to the analytics tracking being done by the SDK.

```swift
extension AppDelegate: AppcuesAnalyticsDelegate {
    func didTrack(analytic: AppcuesAnalytic, value: String?, properties: [String: Any]?, isInternal: Bool) {
        // process and use the analytics tracking information
    }
}
```

After both the Appcues iOS SDK and the delegate implementation are initialized, set the delegate for the Appcues iOS SDK to use. In the usage example below, this is done in `application(_:didFinishLaunchingWithOptions:)` in the `AppDelegate`.

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // after other initialization is complete...
    appcues.analyticsDelegate = self

    return true
}
```

## Using the Analytics Tracking Data

There are two key types of Appcues analytics tracking data to distinguish.

The first type is the internal SDK events - these capture anything that is generated automatically inside of the Appcues SDK, including flow events, session events, and any automatically tracked screens.

The second type is all other analytics - these are all the screens, events, user or group identities that are passed into the SDK from the host application.

These two types are distinguished using the `isInternal` parameter on ``AppcuesAnalyticsDelegate/didTrack(analytic:value:properties:isInternal:)``.

### Amplitude Integration Example

In this example use case, an application would like to observe and track all of the internal Appcues SDK events and send them to Amplitude as well. The other events that originate in the main application codebase are already integrated elsewhere in the codebase. The primary goal is to be able to analyze Appcues flow events, using Amplitude.

In this example, an extension on the `Amplitude` type is created, which adheres to the ``AppcuesAnalyticsDelegate`` protocol. This extension will filter out tracking items so that it is only tracking internal analytics of the `.event` type.

```swift
extension Amplitude: AppcuesAnalyticsDelegate {
    public func didTrack(analytic: AppcuesAnalytic, value: String?, properties: [String: Any]?, isInternal: Bool) {
        // filter out any analytics we're not interested in passing along
        guard isInternal, analytic == .event, let value = value else { return }

        // track with Amplitude
        logEvent(value, withEventProperties: properties)
    }
}
```

After both SDKs have been initialized, set the ``Appcues/analyticsDelegate`` reference.

```swift
appcues.analyticsDelegate = Amplitude.instance()
```

Now, all of the internal events from the Appcues SDK will also be sent to Amplitude, using the `logEvent` function call.