# Migration Guide

Learn more about changes to Appcues iOS SDK.

Appcues iOS SDK follow semantic versions. Accordingly, a major version is incremented when an incompatible API change is made. Below are details for each such version change.  

## 2.x to 3.0 Migration Guide

### Overview

Updating to this release will not require any code changes for most SDK installations.  Code changes would only be required if your app implemented custom experience traits or actions.

### General Changes

#### Removed

- To simplify the public API, `AppcuesExperienceAction` and `AppcuesExperienceTrait` related classes and functions no longer have public visibility. There are no current use cases for extensibility that require these to be public.

## 1.x to 2.0 Migration Guide

### Overview

Updating to this release will not require any code changes for most SDK installations.  Code changes would only be required if your app made anonymous calls with user properties, implemented a custom navigation delegate, or implemented custom experience traits or actions.

### General Changes

#### Removed

- Properties are no longer supported for anonymous users. `Appcues/anonymous(properties:)` has been superseded by ``Appcues/anonymous()``. If you require properties, use ``Appcues/identify(userID:properties:)``.
- Extensions on `SwiftUI.Font.Design` and `SwiftUI.Font.Weight`.

#### Changed

- ``AppcuesNavigationDelegate`` is now responsible for handling universal links in addition to scheme links. Consequently, ``AppcuesNavigationDelegate/navigate(to:openExternally:completion:)`` has a new parameter `openExternally` which indicates whether a link is expecting to be opened in an external browser.

### Custom Action and Trait Changes

#### Removed

- Extension on `Dictionary<String, Any>` to decode plugin configuration values. Use the new `AppcuesExperiencePluginConfiguration` approach detailed below.

#### Renamed

A number of types were renamed to have a standardized prefix of `Appcues`:

| Old Name                              | New Name                                     |
| ------------------------------------- | -------------------------------------------- |
| `ExperienceAction`                    | `AppcuesExperienceAction`                    |
| `ExperienceTrait`                     | `AppcuesExperienceTrait`                     |
| `StepDecoratingTrait`                 | `AppcuesStepDecoratingTrait`                 |
| `ContainerCreatingTrait`              | `AppcuesContainerCreatingTrait`              |
| `ContainerDecoratingTrait`            | `AppcuesContainerDecoratingTrait`            |
| `BackdropDecoratingTrait`             | `AppcuesBackdropDecoratingTrait`             |
| `WrapperCreatingTrait`                | `AppcuesWrapperCreatingTrait`                |
| `PresentingTrait`                     | `AppcuesPresentingTrait`                     |
| `ExperienceContainerViewController`   | `AppcuesExperienceContainerViewController`   |
| `lifecycleHandler`                    | `AppcuesExperienceContainer/eventHandler`    |
| `ExperienceContainerLifecycleHandler` | `AppcuesExperienceContainerEventHandler`     |
| `PageMonitor`                         | `AppcuesExperiencePageMonitor`               |
| `TraitError`                          | `AppcuesTraitError`                          |
| `ExperienceTraitLevel`                | `AppcuesExperiencePluginConfiguration.Level` |

#### Changed

- `AppcuesExperienceTrait` now has a new `metadataDelegate` which supports sharing data between trait types and instances.
- The functionality of decorating traits set at the step level have been updated to apply only to the step on which they are set. New `undecorate()` functions are called to allow a trait to remove its decorations from the container or backdrop:
    - `AppcuesContainerDecoratingTrait` added `undecorate(containerController:)`. This function should reverse the decoration applied in `decorate(containerController:)`
    - `AppcuesBackdropDecoratingTrait` added `undecorate(backdropView:)`. This function should reverse the decoration applied in `decorate(backdropView:)`.
- `AppcuesContainerCreatingTrait` changed it's `createContainer(for:with:)`, which now provides a configured instance of `AppcuesExperiencePageMonitor` instead of requiring the trait to create this object.
    - `AppcuesExperiencePageMonitor` no longer has a public init `init(numberOfPages:currentPage:)`.
- Appcues trait and action initialization has be revised with `AppcuesExperiencePluginConfiguration` supporting `Decodable` models for additional flexibility and robustness.
    - For an `AppcuesExperienceAction`, `init(configuration:)` provides a `configuration` object on which `decode(_:)` can be called with a `Decodable` type.
    - For an `AppcuesExperienceTrait`, `init(configuration:)` provides a `configuration` object on which `decode(_:)` can be called with a `Decodable` type. The former `level` property provided in the trait init is now available from the `level` property. 
- `AppcuesExperienceAction` has updated its `execute(completion:)` function signature to remove the `inContext` parameter. Access to the Appcues instance that's triggering the action should be accessed via a weakly stored reference to the instance provided in the initializers `configuration` (`appcues`) object.
