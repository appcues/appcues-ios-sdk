![AppcuesKit](https://raw.githubusercontent.com/appcues/appcues-ios-sdk/main/Sources/AppcuesKit/AppcuesKit.docc/banner%402x.png)

# Appcues iOS SDK

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/appcues/appcues-ios-sdk/tree/main.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/appcues/appcues-ios-sdk/tree/main)
[![Cocoapods](https://img.shields.io/cocoapods/v/Appcues)](https://cocoapods.org/pods/Appcues)
[![](https://img.shields.io/badge/-documentation-informational)](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/appcues/appcues-ios-sdk/blob/main/LICENSE)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fappcues%2Fappcues-ios-sdk%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/appcues/appcues-ios-sdk)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fappcues%2Fappcues-ios-sdk%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/appcues/appcues-ios-sdk)

Appcues iOS SDK allows you to integrate Appcues experiences into your native iOS and iPadOS apps.

The SDK is a Swift library for sending user properties and events to the Appcues API and retrieving and rendering Appcues content based on those properties and events.

- [Appcues iOS SDK](#appcues-ios-sdk)
  - [🚀 Getting Started](#-getting-started)
    - [Installation](#installation)
      - [Segment](#segment)
      - [Swift Package Manager](#swift-package-manager)
      - [Cocoapods](#cocoapods)
      - [XCFramework](#xcframework)
    - [One Time Setup](#one-time-setup)
      - [Initializing the SDK](#initializing-the-sdk)
      - [Supporting Builder Preview and Screen Capture](#supporting-builder-preview-and-screen-capture)
    - [Identifying Users](#identifying-users)
    - [Tracking Screens and Events](#tracking-screens-and-events)
    - [Anchored Tooltips](#anchored-tooltips)
    - [Embedded Experiences](#embedded-experiences)
  - [🛠 Customization](#-customization)
  - [📝 Documentation](#-documentation)
  - [🎬 Examples](#-examples)
  - [👷 Contributing](#-contributing)
  - [📄 License](#-license)

## 🚀 Getting Started

### Installation

Add the Appcues iOS SDK package to your app. There are several supported installation options. A [tutorial video](https://appcues.wistia.com/medias/m47az4z63o) is also available for reference, showing an installation using Swift Package Manager.

#### Segment

Appcues supports integration with Segment's [analytics-swift](https://github.com/segmentio/analytics-swift) library. To install with Segment, you'll use the [Segment Appcues plugin](https://github.com/appcues/segment-appcues-ios).

#### Swift Package Manager

Add the Swift package as a dependency to your project in Xcode:

1. In Xcode, open your project and navigate to **File** → **Add Packages…**
2. Enter the package URL `https://github.com/appcues/appcues-ios-sdk`
3. For **Dependency Rule**, select **Up to Next Major Version**
4. Click **Add Package**

Alternatively, if your project has a `Package.swift` file, you can add Appcues iOS SDK to your dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/appcues/appcues-ios-sdk", from: "2.0.0"),
]
```

#### Cocoapods

1. Add the pod to your Podfile
    ```rb
    pod 'Appcues'
    ```
2. In Terminal, run
   ```sh
   pod install
   ```

#### XCFramework

An XCFramework is attached with each [release](https://github.com/appcues/appcues-ios-sdk/releases).

1. Download `AppcuesKit.xcframework.zip` attached to the [latest release](https://github.com/appcues/appcues-ios-sdk/releases) and unzip.
2. In Xcode, open your project and navigate to **File** → **Add Files to "\<Project\>"…**
3. Find the XCFramework in the file navigator and select it
4. Ensure the option to "Copy items if needed" is checked and that your app's target is selected
5. Click **Add**
6. Select your project in the **Project navigator**, select your app target and then the **General** tab. Under **Frameworks, Libraries, and Embedded Content**, set AppcuesKit.xcframework to **Embed & Sign**

### One Time Setup

After installing the package, you can reference Appcues iOS SDK by importing the package with `import AppcuesKit`.

#### Initializing the SDK

An instance of the Appcues iOS SDK should be initialized when your app launches. A lifecycle method such as `application(_:didFinishLaunchingWithOptions:)` would be a common location:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  let appcuesConfig = Appcues.Config(
    accountID: <#APPCUES_ACCOUNT_ID#>,
    applicationID: <#APPCUES_APPLICATION_ID#>)
    
  appcues = Appcues(config: appcuesConfig)
}
```

Initializing the SDK requires you to provide two values, an Appcues account ID, and an Appcues mobile application ID. These values can be obtained from your [Appcues settings](https://studio.appcues.com/settings/account). Refer to the help documentation on [Registering your mobile app in Studio](https://docs.appcues.com/article/848-registering-your-mobile-app-in-studio) for more information.

#### Supporting Builder Preview and Screen Capture

During installation, follow the steps outlined in [Configuring the Appcues URL Scheme](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit/urlschemeconfiguring). This is necessary for the complete Appcues builder experience, supporting experience preview, screen capture and debugging. Refer to the [Debug Guide](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit/debugging) for details about using the Appcues debugger.

### Identifying Users

In order to target content to the right users at the right time, you need to identify users and send Appcues data about them. A user is identified with a unique ID.

- `identify(userID:)`

### Tracking Screens and Events

Events are the “actions” your users take in your application, which can be anything from clicking a certain button to viewing a specific screen. Once you’ve installed and initialized the Appcues iOS SDK, you can start tracking screens and events using the following methods:

- `track(name:)`
- `screen(title:)`

### Anchored Tooltips

Anchored tooltips use element targeting to point directly at specific views in your application. For more information about how to configure your application's views for element targeting, refer to the [Anchored Tooltips Guide](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit/anchoredtooltips).

### Embedded Experiences

Add `AppcuesFrameView` instances in your application layouts to support embedded experience content, with a non-modal presentation. For more information about how to configure your application layouts to use frame views, refer to the guide on [Configuring an Appcues Frame](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit/frameconfiguring).

Refer to the full [Getting Started Guide](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit/gettingstarted) for more details.

## 🛠 Customization

Refer to the [Extending Guide](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit/extending) for details.

## 📝 Documentation

SDK Documentation is available at https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit and full Appcues documentation is available at https://docs.appcues.com/

## 🎬 Examples

The `Examples` directory in repository contains full example iOS apps demonstrating different methods of installation and providing references for usage of the Appcues API.

## 👷 Contributing

See the [contributing guide](https://github.com/appcues/appcues-ios-sdk/blob/main/CONTRIBUTING.md) to learn how to get set up for development and how to contribute to the project.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](https://github.com/appcues/appcues-ios-sdk/blob/main/LICENSE) for more information.
