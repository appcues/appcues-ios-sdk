# Identifying and Managing Users

In order to target content to the right users at the right time, you need to identify users and send Appcues data about them.

## Identifying Known Users

> Appcues recommends choosing opaque and hard to guess user IDs, such as a UUID. See the [FAQ for Developers](https://docs.appcues.com/article/159-faq#choosing-a-user-id) for more details about how to choose a User ID.

``Appcues/identify(userID:properties:)``

The inverse of identifying is resetting. For example, if a user logs out of your app. Calling ``Appcues/reset()`` will disable tracking of screens and events until a user is identified again.

### Sender Validation
If your Appcues account is configured for sender validation, pass the user signature in the properties included on the ``Appcues/identify(userID:properties:)`` call. Use the key "appcues:user_id_signature" and the string value of the signature.

```swift
appcues.identify(userID: userID, properties: ["appcues:user_id_signature": signature])
```

This signature will be used in an Authorization header on network requests from the SDK. The Appcues API will use this signature to verify that the requests from the client are authorized using an SDK key configured in Appcues Studio.

## Identifying Anonymous Users

``Appcues/anonymous(properties:)``

The format of anonymous IDs can customized with ``Appcues/Config/anonymousIDFactory(_:)``. Anonymous IDs will always be prefixed with `anon:` by the SDK.
