# Configuring a Custom Component

Define a custom component to be rendered in an experience.

## Overview 

An ``AppcuesCustomComponentViewController`` allows your app to define a custom component that can be rendered in an experience containing a custom component block using the registered `identifier` for the component.

## Implementing a custom component 

Conform a `UIViewController` to the ``AppcuesCustomComponentViewController`` protocol by implementing an initializer, ``AppcuesCustomComponentViewController/init(configuration:actionController:)``.

The initializer provides a ``AppcuesExperiencePluginConfiguration`` object which includes a ``AppcuesExperiencePluginConfiguration/decode(_:)`` method to deserialize the component configuration into a `Decodable` type:

```swift
extension MyViewController: AppcuesCustomComponentViewController {
    struct Config: Decodable {
        let stringProperty: String
        let numberProperty: Double
        let boolProperty: Bool 
    }

    convenience init?(configuration: AppcuesKit.AppcuesExperiencePluginConfiguration, actionController: AppcuesExperienceActions) {
        guard let config = configuration.decode(Config.self) else { return nil }
        
        // Initialize your view controller with the decoded configuration:
        // config.stringProperty, etc
        self.init()
    }
}
```

> Note: It is required that the `UIViewController.preferredContentSize` property be set to the size required by your component. If `preferredContentSize` is not set your custom component may not be allocated any space when rendering in an Appcues experience. There are several approaches to accomplish this including overriding `preferredContentSize` or setting `preferredContentSize` from `viewDidLayoutSubviews()`.

### Invoking actions

Your custom component may want to interact with the Appcues context and manipulate the experience it's embedded in. ``AppcuesCustomComponentViewController/init(configuration:actionController:)`` provides an action controller (``AppcuesExperienceActions``) to accomplish this.

Note that ``AppcuesExperienceActions/triggerBlockActions()`` will invoke the actions added to the custom component in the Appcues Mobile Builder.

### Registering a custom component

Registering a custom component by calling  ``Appcues/registerCustomComponent(identifier:type:)`` when your app starts. Ensure the identifier is an unique string when registering multiple custom components.

```swift
Appcues.registerCustomComponent(identifier: "myViewController", type: MyViewController.self)
```

### Testing a custom component

All registered custom view are listed in the `Debugger` under the `Plugins` section. Refer to <doc:Debugging>.

Provide a ``AppcuesCustomComponentViewController/debugConfig-57bo8`` on your custom component view controller to test an instance of your custom component:

```swift
extension MyViewController {
    static var debugConfig: [String: Any]? {
        [
            "stringProperty": "some string",
            "numberProperty": 3.14,
            "boolProperty": true
        ]
    }
}
```

The debugger page for a custom component instance will also show a list of actions invoked by the custom component.
