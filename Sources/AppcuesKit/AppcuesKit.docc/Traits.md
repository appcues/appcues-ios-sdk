# Understanding the Experience Trait System

Experiences displayed by the Appcues iOS SDK are customizable and extensible via a flexible system of Experience Traits.

## Overview

An ``ExperienceTrait`` modifies the how an entire experience, or a particular step in an experience is displayed. A trait of a specific _type_ has _capabilities_ that modify the way an experience is displayed to the user. Furthermore a trait can be applied at multiple _levels_ which determines which parts of the experience are impacted by the trait instance.

Traits operate on the following view controller hierarchy, providing the ability to create and modify the controllers where appropriate:

![Step view controllers are children of a step container view controller which in turn may be a child of a step wrapper view controller](trait-controllers.png)

## Trait Types

Every trait has a ``ExperienceTrait/type`` property that must be a unique name identifying the trait. Best practice is to prefix the `type` with your organization name, resulting in the format `@org/name` (e.g. `@appcues/modal`).

Attempting to register a trait for a type that exists already will crash in debug builds and fail silently otherwise.

## Trait Capabilities

An experience trait must adopt at least one of the following capabilities to have any effect, and may adopt more than one for more complex functionality.

### Step Decorating

A ``StepDecoratingTrait`` modifies the `UIViewController` that encapsulates the contents of a specific step in the experience.

### Container Creating

A ``ContainerCreatingTrait`` is responsible for creating the `UIViewController` (specifically a ``ExperienceContainerViewController``) that holds the experience step(s) being presented. The returned controller must call the ``ExperienceContainerLifecycleHandler`` methods at the appropriate times.

> Only a single ``ContainerCreatingTrait`` will be applied in the process of displaying an experience step even if multiple are defined.

### Container Decorating

A ``ContainerDecoratingTrait`` modifies the container view controller created by an ``ContainerCreatingTrait``.

### Backdrop Decorating

A  ``BackdropDecoratingTrait`` modifies the backdrop `UIView` that may be included in the presented experience.

>  Not all experiences will include a backdrop, and a ``BackdropDecoratingTrait`` will not be invoked if the experience does not include a backdrop.

### Wrapper Creating

A ``WrapperCreatingTrait`` creates a `UIViewController` that wraps the ``ExperienceContainerViewController``. This trait is also responsible for adding the backdrop view to the appropriate (if any) place.

> Only a single ``WrapperCreatingTrait`` will be applied in the process of displaying an experience step even if multiple are defined.

### Presenting

A ``PresentingTrait`` is responsible for providing the ability to show and hide the experience.

> Only a single ``PresentingTrait`` will be applied in the process of displaying an experience step even if multiple are defined.

## Trait Levels

The Appcues mobile experience data model allows for traits to be specified at the experience level, at the step-group level, or at the step level. 

- Experience-level traits modify the entire experience and are applied when any step of the experience is being displayed.
- Group-level traits apply when any of child steps of the group is being displayed. 
- Step-level `Decorating` traits are scoped to be applied only when the specific step is being displayed. A `Creating` or `Presenting` trait set at the step-level will be ignored because applying them would leak beyond the specific step an impact the display of any sibling steps.

In practice this distinction looks like this in the experience data model:

```json
{
    ...
    "traits": [
        // Experience-level traits
        // Presenting and Creating traits propagated to each group
        // Decorating traits are propagated to every child step
    ],
    "steps": [
        {
            ...
            "traits": [
                // Group-level traits
                // Presenting and Creating traits are applied, taking precedence over traits of the same type at the experience-level
                // Decorating traits are propagated to every child step in the group
            ],
            "children": [
                {
                    ...
                    "content": { ... },
                    "traits": [
                        // Step-level traits for the first step
                        // Presenting and Creating traits are ignored
                        // Decorating traits only
                    ]
                }
            ]
        },
        {
            ...
            "content": { ... },
            "traits": [
                // Step-level traits for the second step
                // Presenting and Creating traits are ignored
                // Decorating traits only
            ]
        }
    ]
}
```

Only a single instance of each trait type may be included in the `traits` array at any given level. If multiple traits with the same `id` are included in the same array, the experience is invalid, an error will be logged, and the experience will not display. The most specific instance of a trait type will take precedence over a trait of the same type specified at a higher level.

A trait is made aware of the level at which it is being applied by the ``ExperienceTraitLevel`` passed into ``ExperienceTrait/init(configuration:level:)``. A trait may choose to alter its behavior depending on the `level` at which it is applied.

For example, a trait might simultaneously conform to ``StepDecoratingTrait`` and ``ContainerDecoratingTrait`` and the choose to apply it's decoration in only one of those contexts:

```swift
let level: ExperienceTraitLevel

required init?(config: [String: Any]?, level: ExperienceTraitLevel) {
    self.level = level
}

// StepDecoratingTrait
func decorate(stepController viewController: UIViewController) throws {
    guard level == .step else { return }

    // do something when the trait was applied a step level
}

// ContainerDecoratingTrait
func decorate(containerController: ExperienceContainerViewController) throws {
    guard level == .group else { return }

    // do something when the trait was applied a group level
}
```

## Trait Application Sequence

Trait capabilities are applied in a defined sequence, and a trait with multiple capabilities will have its capabilities applied piecewise.

![Begin Step X -> Create Step View -> Step Decorating -> Container Creating -> Container Decorating -> Wrapper Creating -> Backdrop Decorating -> Presenting](trait-flow.png)

> A trait with multiple capabilities may, in certain circumstances, not have all its capabilities applied. A ``BackdropDecoratingTrait`` will not be applied if no ``WrapperCreatingTrait`` is present. Additionally, single trait capabilities (i.e. ``ContainerCreatingTrait``, ``WrapperCreatingTrait``, and ``PresentingTrait``) will ignore all but the first trait model in the most specific context that provides the capability. Additionally, ``ContainerCreatingTrait``, ``WrapperCreatingTrait``, and ``PresentingTrait`` capabilities provided at the step level within a group are ignored.

## Sharing Data Across Traits

There may be cases where values or data from one trait type are required for the successful rendering of another trait type. Similarly, there may be cases where you wish to coordinate a transition between traits of the same type applied at the step-level. In both these cases, the ``TraitMetadataDelegate`` provides a mechanism to manage data across trait instances.

Every ``ExperienceTrait`` includes a ``ExperienceTrait/metadataDelegate`` that supports three key features:

1. Set a metadata value for reading by other traits.
2. Get a metadata value via a handler block.
3. Publish a new metadata value on demand, notifying all other traits that have a registered handler.

For example, there is a trait `@appcues/step-transition-animation` that sets two metadata values `animationDuration` and `animationEasing` using ``TraitMetadataDelegate/set(_:)``. Other traits can read these values using ``TraitMetadataDelegate/registerHandler(for:animating:handler:)`` to set consistent animations across multiple traits. 

## Error Handling

There may be cases where a trait is unable to perform its intended capability. If this happens, it's preferred that a non-essential trait fail silently so that the experience can still be displayed to the user. However if a trait implementation is essential, it may throw a ``TraitError`` that will prevent the experience from being displayed and log an error with the Appcues platform.

For example, a ``ContainerCreatingTrait`` that is unable to create a proper container instance may throw a ``TraitError`` with a ``TraitError/description`` explaining the nature of the error. The description message will be visible in Appcues Studio.

## Topics

### Capabilities

- ``StepDecoratingTrait``
- ``ContainerCreatingTrait``
- ``ContainerDecoratingTrait``
- ``BackdropDecoratingTrait``
- ``WrapperCreatingTrait``
- ``PresentingTrait``

### Containers

- ``ExperienceContainerViewController``
- ``ExperienceContainerLifecycleHandler``
- ``PageMonitor``

### Error Handing

- ``TraitError``
