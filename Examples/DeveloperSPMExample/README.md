# Appcues SPM Example App

This is a simple iOS app that integrates with Appcues iOS SDK using [Swift Package Manager](https://swift.org/package-manager/).

## 🚀 Setup

This example app requires you to fill in an Appcues Account ID and an Appcues Application ID before the app will compile. You can enter your own values found in [Appcues Studio](https://studio.appcues.com), or use the following test values:

```
APPCUES_ACCOUNT_ID=103523
APPCUES_APPLICATION_ID=8bc9bdb8-6546-4781-95f8-75abee12fa7a
```

## ✨ Functionality

The example app demonstrates the core functionality of the Appcues iOS SDK across 4 screens.

### Sign In Screen

This screen is identified as `Sign In` for screen targeting.

Provide a User ID for use with `Appcues.identify()` or select an anonymous ID using `Appcues.anonymous()`.

### Events Screen

This screen is identified as `Trigger Events` for screen targeting.

Two buttons demonstrate `Appcues.track()` calls.

The navigation bar also includes a button to launch the in-app debugger with `Appcues.debug()`.

### Profile Screen

This screen is identified as `Update Profile` for screen targeting.

Textfields are included to update the profile attributes for the current user using `Appcues.identify()`.

The navigation bar also includes a button to sign out and navigate back to the Sign In Screen along with calling `Appcues.reset()`.

### Group Screen

This screen is identified as `Update Group` for screen targeting.

A textfield is included to set the group for the current user using `Appcues.group()`.

## Deep Links

The app supports the following deep links.

| Screen  | Link                      |
| ------- | ------------------------- |
| Sign In | appcues-example://signin  |
| Events  | appcues-example://events  |
| Profile | appcues-example://profile |
| Group   | appcues-example://group   |

## Universal Links

The app supports the following universal links.

> These links only work when this example app is compiled with the Appcues Team ID and Bundle ID specified in the test server [apple-app-site-association](https://appcues-mobile-links.netlify.app/.well-known/apple-app-site-association) file.

| Screen  | Link                      |
| ------- | ------------------------- |
| Events  | https://appcues-mobile-links.netlify.app/events  |
| Profile | https://appcues-mobile-links.netlify.app/profile |
| Group   | https://appcues-mobile-links.netlify.app/group   |