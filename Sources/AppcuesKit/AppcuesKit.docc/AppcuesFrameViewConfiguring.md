# Configuring AppcuesFrameViews

Using `AppcuesFrameView` instances in your layouts will allow you to embed inline Appcues experience content in your app. This style of pattern is non-modal in the user's experience, differing from modals and tooltips used in mobile flows. Any number of desired embedded experiences can be rendered in the application at any given time.

## Adding AppcuesFrameView in UIKit

When using UIKit for your application layouts, insert ``AppcuesFrameView`` instances wherever you would like Appcues embedded experience content to potentially appear. By default, these views will not take up any space in the rendered layout. Only when qualified experience content is targeted to these frames will they actually be visible. You can think of this process as reserving placeholder locations in your application UI for potential additional content. An ``AppcuesFrameView`` can be used in either Storyboards or coded UI.

## Registering an AppcuesFrameView with the Appcues SDK

Once the frames have been added to the layout, the last step is to register the view instances with the Appcues SDK, so that experience content can be injected, if qualified. Each frame should use a unique `frameID` (String). This identifier is used when building embedded experiences, informing Appcues the exact location in your app that the content should be targeted.

Call the ``Appcues/register(frameID:for:on:)`` function to register each frame instance, when that view is loaded in you application. This function supplies the unique `frameID` value, the instance of the ``AppcuesFrameView``, and the `UIViewController` parent of that frame view.

```swift
appcues.register(frameID: "frame1", for: appcuesFrame1, on: self)
```

Once the frame views are registered, the integration is complete.

## Using AppcuesFrameView with SwiftUI

The Appcues SDK also supports embedded experience content in layouts using SwiftUI. An ``AppcuesFrame`` can be used to place a frame in your layout, passing the Appcues SDK instance and `frameID` values to register the view.

```swift
VStack {
    AppcuesFrame(appcues: appcues, frameID: "frame1")
}
```

## Other Considerations

* The `frameID` registered with Appcues for each frame should ideally be globally unique in the application, but at least must be unique on the screen where experience content may be targeted. 
* Some ``AppcuesFrameView`` instances may not be visible on the screen when it first loads, if they are lower down on a scrolling page, for instance. However, when they scroll into view, any qualified content on that screen will then render into that position.
* Using ``AppcuesFrameView`` in views with cell re-use (ex. `UITableView` or `UICollectionView`) is supported, but may require re-registering with a new `frameID` when cells are re-used, depending on your use case.
* When configuring settings for triggering embedded experience content, make sure that the experience is triggered on the same screen where the target `frameID` exists.
* To preview embedded content from the mobile builder inside your application, you may need to initiate the preview and then navigate to the screen where the target `frameID` exists.
