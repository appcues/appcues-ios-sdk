# Understanding the Experience Trait System

Experiences displayed by the Appcues iOS SDK are customizable and extensible via a flexible system of Experience Traits.

## Overview

An ``ExperienceTrait`` modifies the how an entire experience, or a particular step in an experience is displayed. A trait has capabilities that modify the way an experience is displayed to the user.

Traits operate on the following view controller hierarchy, providing the ability to create and modify the controllers where appropriate:

![Step view controllers are children of a step container view controller which in turn may be a child of a step wrapper view controller](trait-controllers.png)

## Trait Capabilities

An experience trait must adopt at least one of the following capabilities to have any effect, and may adopt more than one for more complex functionality.

Trait capabilities are applied in a defined sequence, and a trait with multiple capabilities will have its capabilities applied piecewise.

![Begin Step X -> Grouping -> Create Step View -> Step Decorating -> Container Creating -> Container Decorating -> Wrapper Creating -> Backdrop Decorating -> Presenting](trait-flow.png)

> A trait with multiple capabilities may, in certain circumstances, not have all its capabilities applied. A ``BackdropDecoratingTrait`` will not be applied if no ``WrapperCreatingTrait`` is present. Additionally, single trait capabilities will ignore subsequent traits providing the capability once the first has been applied. 

### Step Decorating

A ``StepDecoratingTrait`` modifies the `UIViewController` that encapsulates the contents of a specific step in the experience.

### Container Creating

A ``ContainerCreatingTrait`` is responsible for creating the `UIViewController` (specifically a ``ExperienceStepContainer``) that holds the experience step(s) being presented. The returned controller must call the ``ExperienceContainerLifecycleHandler`` methods at the appropriate times.

> Only a single ``ContainerCreatingTrait`` will be applied in the process of displaying an experience step even if multiple are defined. The order of precedence is experience-level traits and then step-level traits, in their order in the experience object. 

### Container Decorating

A ``ContainerDecoratingTrait`` modifies the container view controller created by an ``ContainerCreatingTrait``.

### Backdrop Decorating

A  ``BackdropDecoratingTrait`` modifies the backdrop `UIView` that may be included in the presented experience.

>  Not all experiences will include a backdrop, and a ``BackdropDecoratingTrait`` will not be invoked if the experience does not include a backdrop.

### Wrapper Creating

A ``WrapperCreatingTrait`` creates a `UIViewController` that wraps the ``ExperienceStepContainer``. This trait is also responsible for adding the backdrop view to the appropriate (if any) place.

> Only a single ``WrapperCreatingTrait`` will be applied in the process of displaying an experience step even if multiple are defined. The order of precedence is experience-level traits and then step-level traits, in their order in the experience object. 

### Presenting

A ``PresentingTrait`` is responsible for providing the ability to show and hide the experience.

> Only a single ``PresentingTrait`` will be applied in the process of displaying an experience step even if multiple are defined. The order of precedence is experience-level traits and then step-level traits, in their order in the experience object. 

## Experience-Level and Step-Level Traits

The Appcues mobile experience data model allows for traits to be specified at the experience level or at the step level. Experience-level traits modify the entire experience and apply to all steps in the experience (with the exception of grouped traits; see below). Step-level traits are scoped to be applied only when the specific step is being displayed.

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
                // Step-level traits for the first step
            ]
        },
        {
            ...
            "traits": [
                // Step-level traits for the second step
            ]
        }
    ]
}
```

## Trait Grouping Behavior

There are scenarios where experience-level traits may be intended to modify only a subset of the steps in an experience. For example, an experience with a single, full-screen modal followed by a standard dialog-style modal displaying as a carousel with two steps.

To accomplish this, the Appcues iOS SDK includes two special traits, `@appcues/group` and `@appcues/group-item`. `@appcues/group` is an experience-level trait that defines a `groupID`, and `@appcues/group-item` is a step-level trait that references a `groupID` to identify the step as being part of the defined group. Other experience-level traits may also reference the `groupID` from their `config` object to identify themselves as only applying when a step from that group is being displayed to a user. 

The experience model for this example would include the following:

```json
{
    ...
    "traits": [
        // 1. Define the group
        {
            "type": "@appcues/group",
            "config": {
                "groupID": "11eef82d-f2df-4aeb-a085-07f6c0b92663"
            }
        },
        {
            "type": "@appcues/modal",
            "config": {
                // 2. Identify this modal trait as being part of the defined group
                "groupID": "11eef82d-f2df-4aeb-a085-07f6c0b92663",
                "presentationStyle": "dialog"
            }
        }
    ],
    "steps": [
        {
            // Step 1
            ...
            "traits": [
                {
                    "type": "@appcues/modal",
                    "config": {
                        "presentationStyle": "fullScreen"
                    }
                }
            ]
        },
        {
            // Step 2
            ...
            "traits": [
                // 3. Indicate this step is part of the group
                {
                    "type": "@appcues/group-item",
                    "config": {
                        "groupID": "11eef82d-f2df-4aeb-a085-07f6c0b92663"
                    }
                }
            ]
        },
        {
            // Step 3
            ...
            "traits": [
                // 3. Indicate this step is part of the group
                {
                    "type": "@appcues/group-item",
                    "config": {
                        "groupID": "11eef82d-f2df-4aeb-a085-07f6c0b92663"
                    }
                }
            ]
        }
    ]
}
```

> Any custom trait wishing to be groupable as an experience-level trait **must** map the `groupID` value in its ``ExperienceTrait/init(config:)`` with the following: `self.groupID = config?["groupID"] as? String`

Use of `@appcues/group` and `@appcues/group-item` is how an ``ContainerCreatingTrait`` can be give more than one step to include. When any step in the group is being prepared to be shown, all other steps in the group are prepared as well. Note that all step-level traits from the group will be applied to the group as a whole.  

> An experience may have multiple groups (i.e. have multiple experience-level `@appcues/group` traits), but each step may only be part of a single group (i.e. a step may only have a single `@appcues/group-item` trait).

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

- ``ExperienceStepContainer``
- ``ExperienceContainerLifecycleHandler``

### Error Handing

- ``TraitError``
