# Understanding the Experience Trait System

Experiences displayed by the Appcues iOS SDK are customizable and extensible via a flexible system of Experience Traits.

## Overview

An ``ExperienceTrait`` modifies the how an entire experience, or a particular step in an experience is displayed. A trait has capabilities that modify the way an experience is displayed to the user.

Traits operate on the following view controller hierarchy, providing the ability to create and modify the controllers where appropriate:

![Step view controllers are children of a step container view controller which in turn may be a child of a step wrapper view controller](trait-controllers.png)

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

## Experience-Level, Group-Level, and Step-Level Traits

The Appcues mobile experience data model allows for traits to be specified at the experience level, at the step-group level, or at the step level. Experience-level traits modify the entire experience and are applied when any step of the experience is being displayed. Group-level traits apply when any of child steps of the group is being displayed. Step-level traits are scoped to be applied only when the specific step is being displayed.

In practice this distinction looks like this in the experience data model:

```json
{
    ...
    "traits": [
        // Experience-level traits
    ],
    "steps": [
        {
            ...
            "traits": [
                // Group-level traits
            ],
            "children": [
                {
                    ...
                    "content": { ... },
                    "traits": [
                        // Step-level traits for the first step
                    ]
                }
            ]
        },
        {
            ...
            "content": { ... },
            "traits": [
                // Step-level traits for the second step
            ]
        }
    ]
}
```

## Trait Application Sequence

Trait capabilities are applied in a defined sequence, and a trait with multiple capabilities will have its capabilities applied piecewise.

![Begin Step X -> Create Step View -> Step Decorating -> Container Creating -> Container Decorating -> Wrapper Creating -> Backdrop Decorating -> Presenting](trait-flow.png)

> A trait with multiple capabilities may, in certain circumstances, not have all its capabilities applied. A ``BackdropDecoratingTrait`` will not be applied if no ``WrapperCreatingTrait`` is present. Additionally, single trait capabilities (i.e. ``ContainerCreatingTrait``, ``WrapperCreatingTrait``, and ``PresentingTrait``) will ignore all but the first trait model providing the capabilitity. The order of precedence is experience-level traits and then step-level traits, in their order in the experience object. 

## Error Handling

There may be cases where a trait is unable to perform its intended capability. If this happens, it's preferred that a non-essential trait fail silently so that the experience can still be displayed to the user. However if a trait implemention is essential, it may throw a ``TraitError`` that will prevent the experience from being displayed and log an error with the Appcues platform.

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
