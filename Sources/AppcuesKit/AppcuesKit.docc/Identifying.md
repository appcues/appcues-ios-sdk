# Identifying and Managing Users

In order to target content to the right users at the right time, you need to identify users and send Appcues data about them.

## Identifying Known Users

> Appcues recommends choosing opaque and hard to guess user IDs, such as a UUID. See the [FAQ for Developers](https://docs.appcues.com/article/159-faq#choosing-a-user-id) for more details about how to choose a User ID.

``Appcues/identify(userID:properties:)``

The inverse of identifying is resetting. For example, if a user logs out of your app. Calling ``Appcues/reset()`` will disable tracking of screens and events until a user is identified again.

## Indentifying Anonymous Users

``Appcues/anonymous(properties:)``

The format of anonymous ID's can customized with ``Appcues/Config/anonymousIDFactory(_:)``.
