# Tracking Screens and Events

Events are the “actions” your users take in your application, which can be anything from clicking a certain button to viewing a specific screen.

## Tracking Screens

A screen should be tracked with a call to ``Appcues/screen(title:properties:)`` each time the screen appears to the user.

For example, in a `UIKit` application:

```swift
override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    appcues.screen(title: "Screen Name")
}
```

## Tracking Events

Tracking events lets you target Appcues content based on actions people have or have not taken in your app, and also see the impact of your flow content on user behaviors. An event is tracked with a call to ``Appcues/track(name:properties:)``.

## Automatic Screen Tracking

The Appcues iOS SDK supports basic automatic screen tracking for `UIKit`-based apps. This is enabled with a call to ``Appcues/trackScreens()``.

> Manual screen tracking should be preferred to automatic screen tracking because it allows fine-grained control over the screen name being tracked, includes the option to track custom properties, and eliminates the potential for missed or duplicate screens.
