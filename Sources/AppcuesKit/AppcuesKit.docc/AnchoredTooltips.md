# Configuring Views for Anchored Tooltips

The Appcues iOS SDK supports anchored tooltips targeting views built with `UIKit` or `SwiftUI`.

Instrumenting your application views as described below allows the Appcues iOS SDK to create a mobile view selector. This selector is used by the Appcues Mobile Builder to create and target anchored tooltips. When a user qualifies for a flow, this selector is used to render the anchored tooltip content in the correct location.

## Instrumenting UIKit Views

The following `UIView` properties are used to identify elements, in order of precedence:

* [`accessibilityIdentifier`](https://developer.apple.com/documentation/uikit/uiaccessibilityidentification/1623132-accessibilityidentifier) - commonly used for Xcode UI testing, and generally a good practice to include on core views in the application to help identify.
* [`tag`](https://developer.apple.com/documentation/uikit/uiview/1622493-tag) - an integer value that can be used to identify view objects in your application.
* [`accessibilityLabel`](https://developer.apple.com/documentation/objectivec/nsobject/1615181-accessibilitylabel) - a property used in assistive applications, such as VoiceOver, to convey information to users with disabilities, to help them use the app. In addition to being a good practice to use to support core accessibility features on iOS, it can also help with Appcues element targeting. It is considered a lower priority property for selector usage, however, due to the fact that the descriptive strings can often be non-unique throughout the application and they may also be localized to the user's preferred language and not maintain consistency with the label used when the flow was built.

At least one identifiable property must be set. Not all are required. The best way to ensure great performance of iOS anchored tooltips in Appcues is to set a unique `accessibilityIdentifier` on each `UIView` element that may be targeted.

These properties are available on any UIView derived type, and can be set programmatically in Swift as follows:

```swift
let button = UIButton()
button.accessibilityIdentifier = "btnSaveProfile"
button.accessibilityLabel = "Save"
button.tag = 1234
```

These properties are also available in Xcode Interface Builder, used for Storyboard UI development. Click on the view and select the Identity inspector tab to see the Accessibility section and set related properties. The `tag` is also visible to edit on the Attributes inspector. These properties can also be set using the User Defined Runtime Attributes section of the Identity inspector for a selected element in Interface Builder.

> Tip: For the common use case of `UITabBarController` and its associated `UITabBar` items, the Appcues iOS SDK will automatically generate index-based selectors for each item to use for targeting tooltips. No additional code is required in your application if you would like to target the items in a `UITabBar` in your application's screen by index.

## Instrumenting SwiftUI Views

iOS Applications using SwiftUI can also identify `View` elements. A `View` extension `appcuesView(identifier:)` is provided by the Appcues iOS SDK to support this use case. The `identifier` String value must be unique on the screen where an anchored tooltip may be targeted.

The following example shows how this would be added to a SwiftUI `Button` View:

```swift
Button("Save Profile") {
    onSaveProfile()
}
.appcuesView(identifier: "btnSaveProfile")
```

## Other Considerations

### Selector Uniqueness
Ensure that view identifiers used for selectors are unique within the visible views on the screen at the time an anchored tooltip is attempting to render. If no unique match is found, the Appcues flow will terminate with an error. It is not required that selectors are globally unique across the application, but they must be on any given screen layout.

Using multiple selector properties is another way to ensure uniqueness. For instance, if two views in a layout have the same `accessibilityLabel`, but different `accessibilityIdentifier` values, a selector will be able to find the unique match by finding the element that matches both properties exactly.

### Consistent View Identifiers
Maintain consistency with view identifiers as new versions of the app are released. For example, if a button was using an identifier like "Save Profile" in several versions of the application, then changed to "Save" - this would break the ability for selectors using "Save Profile" to be able to find that view and target a tooltip in the newer versions of the app. You could build multiple flows targeting different versions of the application, but it helps keep things simplest if consistent view identifiers can be maintained over time.
