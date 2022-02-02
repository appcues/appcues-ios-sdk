# Extending Appcues Experiences

Appcues Experiences are designed to be flexible and powerful without requiring any customization. However, customization is possible as part of the following patterns.

## Custom Experience Actions

An ``ExperienceAction`` is a behavior triggered from an interaction with an experience, for example tapping a button.

An action can be registered with ``Appcues/register(action:)``.

## Custom Experience Traits

An ``ExperienceTrait`` modifies the how an entire experience, or a particular step in an experience is displayed. A trait has capabilities that modify the way an experience is displayed to the user.

A trait can be registered with ``Appcues/register(trait:)``.

For more see <doc:Traits>.
