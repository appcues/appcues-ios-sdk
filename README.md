# Appcues iOS SDK

Appcues iOS SDK allows you to integrate Appcues experiences into your native iOS and iPadOS apps.

The SDK is a Swift library for sending user properties and events to the Appcues API and retrieving and rendering Appcues content based on those properties and events.

- [Appcues iOS SDK](#appcues-ios-sdk)
  - [🚀 Getting Started](#-getting-started)
    - [Installation](#installation)
      - [Segment](#segment)
      - [Swift Package Manager](#swift-package-manager)
      - [Cocoapods](#cocoapods)
    - [One Time Setup](#one-time-setup)
      - [Initializing the SDK](#initializing-the-sdk)
      - [Supporting Debugging and Experience Previewing](#supporting-debugging-and-experience-previewing)
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
3. For **Dependency Rules**, select **Branch** (with branch set to `main`)
4. Click **Add Package**

Alternatively, if your project has a `Package.swift` file, you can add Appcues iOS SDK to your dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/appcues/appcues-ios-sdk", .branch("main"))
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

### One Time Setup

After installing the package, you can reference Appcues iOS SDK by importing the package with `import AppcuesKit`.

#### Initializing the SDK

An instance of the Appcues iOS SDK should be initialized when your app launches. A lifecycle method such as `application(_:didFinishLaunchingWithOptions:)` in would be a common location:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  let appcuesConfig = Appcues.Config(
    accountID: <#APPCUES_ACCOUNT_ID#>,
    applicationID: <#APPCUES_APPLICATION_ID#>)
    
  appcues = Analytics(configuration: configuration)
}
```

Initializing the SDK requires you to provide two values, an Appcues account ID, and an Appcues mobile application ID. These values can be obtained from your [Appcues settings](https://studio.appcues.com/settings/account).

#### Supporting Debugging and Experience Previewing

Supporting debugging and experience previewing is not required for the Appcues iOS SDK to function, but it is necessary for the optimal Appcues builder experience. Refer to the [Debug Guide](https://github.com/appcues/appcues-ios-sdk/blob/main/Sources/AppcuesKit/AppcuesKit.docc/Debugging.md) for details.

### Tracking Screens and Events

Events are the “actions” your users take in your application, which can be anything from clicking a certain button to viewing a specific screen. Once you’ve installed and initialized the Appcues iOS SDK, you can start tracking screens and events using the following methods:

- `identify(userID:)`
- `track(name:)`
- `screen(title:)`

Refer to the full [Getting Started Guide](https://github.com/appcues/appcues-ios-sdk/blob/main/Sources/AppcuesKit/AppcuesKit.docc/GettingStarted.md) for more details.

## 🛠 Customization

Refer to the [Extending Guide](https://github.com/appcues/appcues-ios-sdk/blob/main/Sources/AppcuesKit/AppcuesKit.docc/Extending.md) for details.

## 📝 Documentation

Full documentation is available at https://docs.appcues.com/

## 🎬 Examples

The `Examples` directory in repository contains full example iOS apps demonstrating different methods of installation and providing references for usage of the Appcues API.

## 👷 Contributing

See the [contributing guide](https://github.com/appcues/appcues-ios-sdk/blob/main/CONTRIBUTING.md) to learn how to get set up for development and how to contribute to the project.

## 📄 License

This project is licensed under the MIT License. See [LICENSE](https://github.com/appcues/appcues-ios-sdk/blob/main/LICENSE) for more information.
