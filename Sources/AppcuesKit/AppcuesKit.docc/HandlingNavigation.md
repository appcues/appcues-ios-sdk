# Handling In-App Navigation

The Appcues iOS SDK calls deep links (either universal links or scheme links) within your app.

## Overview

Deep link handling is done automatically where possible. In cases where custom handling of linking behavior is required, use ``AppcuesNavigationDelegate``.

## Universal Links

You must implement `UIApplicationDelegate.application(_:continue:restorationHandler:)` to handle your universal links. Refer to <doc:UniversalLinking>.

## Scheme Links

By default scheme links are opened by the Appcues iOS SDK using the standard `UIApplicationDelegate.application(_:continue:restorationHandler:)` method.

## Overriding Link Handling Behavior

If your deep link handling involves asynchronous operations or animations, the default handling may complete before the navigation to the new screen is fully completed. This may be undesirable if an Appcues flow is targeted to specific elements of the destination screen.

To opt in to custom handling of deep link execution, implement ``AppcuesNavigationDelegate``. When set on ``Appcues/navigationDelegate``, this protocol allows an application to fine tune control of navigation between screens when triggered by an Appcues experience.
