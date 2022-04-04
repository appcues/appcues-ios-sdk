# Working with Logs

Appcues for iOS can be configured to enable logging via Apple's unified logging system, ensuring logs are accessible, performant, and private.

## Overview

Logging is disabled by default and no logs are generated when logging is disabled. When enabled, log are captured at levels corresponding to their importance. An error-level log may indicate why an Appcues experience failed to display. Debug-level logs contain much more granular information about the internal operation of the Appcues SDK. 

## Enable Logging

Logging is enabled via the configuration of your ``Appcues`` instance. Call ``Appcues/Config/logging(_:)`` with a value of `true`.

## Viewing Logs

Once enabled, logs can be viewed several different ways:

### Console

Logs can be inspected using Console.app. All logs from the Appcues SDK are generated under the `com.appcues.sdk` subsystem and can be easily filtered via a search.

### Xcode

Log messages will appear in the Xcode console when running your app attached to the debugger.

### Terminal

Debug-level logs specific to the Appcues iOS SDK from a simulator can be streamed via a Terminal session:

```sh
xcrun simctl spawn booted log stream --debug --predicate 'subsystem == "com.appcues.sdk"'
```
