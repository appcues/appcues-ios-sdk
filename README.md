![AppcuesKit](https://raw.githubusercontent.com/appcues/appcues-ios-sdk/main/Sources/AppcuesKit/AppcuesKit.docc/banner%402x.png)

# Appcues iOS SDK

[![CircleCI](https://circleci.com/gh/appcues/appcues-ios-sdk/tree/main.svg?style=shield&circle-token=16de1b3a77b1e448557552caa17a5c33ec38b679)](https://circleci.com/gh/appcues/appcues-ios-sdk/tree/main)
[![Cocoapods](https://img.shields.io/cocoapods/v/Appcues)](https://cocoapods.org/pods/Appcues)
[![](https://img.shields.io/badge/-documentation-informational)](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/appcues/appcues-ios-sdk/blob/main/LICENSE)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fappcues%2Fappcues-ios-sdk%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/appcues/appcues-ios-sdk)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fappcues%2Fappcues-ios-sdk%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/appcues/appcues-ios-sdk)

>NOTE: This is a pre-release project for testing as a part of our mobile beta program. If you are interested in learning more about our mobile product and testing it before it is officially released, please [visit our site](https://www.appcues.com/mobile) and request early access.  
>
>If you have been contacted to be a part of our mobile beta program, we encourage you to try out this library and  provide feedback via Github issues and pull requests. Please note this library will not operate if you are not part of the mobile beta program.

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
      - [Supporting Debugging and Experience Previewing](#supporting-debugging-and-experience-previewing)
    - [Identifying Users](#identifying-users)
    - [Tracking Screens and Events](#tracking-screens-and-events)
  - [🛠 Customization](#-customization)
  - [📝 Documentation](#-documentation)
  - [🎬 Examples](#-examples)
  - [👷 Contributing](#-contributing)
  - [📄 License](#-license)

## 🚀 Getting Started

### Installation

Add the Appcues iOS SDK package to your app. There are several supported installation options.

#### Segment

Appcues supports integration with Segment's [analytics-swift](https://github.com/segmentio/analytics-swift) library. To install with Segment, you'll use the [Segment Appcues plugin](https://github.com/appcues/segment-appcues-ios).

#### Swift Package Manager

Add the Swift package as a dependency to your project in Xcode:

1. In Xcode, open your project and navigate to **File** → **Add Packages…**
2. Enter the package URL `https://github.com/appcues/appcues-ios-sdk`
3. For **Dependency Rules**, select **Exact Version** and enter the latest pre-release beta version `1.0.0-beta.4`
4. Click **Add Package**

Alternatively, if your project has a `Package.swift` file, you can add Appcues iOS SDK to your dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/appcues/appcues-ios-sdk", .branch("main"))
]
```

#### Cocoapods

1. Add the pod to your Podfile (The pre-release version needs to be explicitly included until 1.0.0 is released)
    ```rb
    pod 'Appcues', '1.0.0-beta.4'
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

Initializing the SDK requires you to provide two values, an Appcues account ID, and an Appcues mobile application ID. These values can be obtained from your [Appcues settings](https://studio.appcues.com/settings/account).

#### Supporting Debugging and Experience Previewing

Supporting debugging and experience previewing is not required for the Appcues iOS SDK to function, but it is necessary for the optimal Appcues builder experience. Refer to the [Debug Guide](https://appcues.github.io/appcues-ios-sdk/documentation/appcueskit/debugging) for details.

### Identifying Users

In order to target content to the right users at the right time, you need to identify users and send Appcues data about them. A user is identified with a unique ID.

- `identify(userID:)`

### Tracking Screens and Events

Events are the “actions” your users take in your application, which can be anything from clicking a certain button to viewing a specific screen. Once you’ve installed and initialized the Appcues iOS SDK, you can start tracking screens and events using the following methods:

- `track(name:)`
- `screen(title:)`

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
