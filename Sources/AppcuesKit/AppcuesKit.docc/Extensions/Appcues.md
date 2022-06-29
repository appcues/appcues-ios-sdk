# ``AppcuesKit/Appcues``

## Topics

### Initializing

- ``Appcues/Config``
- ``Appcues/init(config:)``

### Managing Users

- <doc:Identifying>
- ``Appcues/identify(userID:properties:)``
- ``Appcues/anonymous(properties:)``
- ``Appcues/group(groupID:properties:)``
- ``Appcues/reset()``

### Tracking Screens and Events

- <doc:Tracking>
- ``Appcues/track(name:properties:)``
- ``Appcues/screen(title:properties:)``
- ``Appcues/trackScreens()``

### Showing Experiences

- ``Appcues/show(experienceID:completion:)``

### Debugging

- <doc:Debugging>
- ``Appcues/debug()``
- ``Appcues/filterAndHandle(_:)``
- ``Appcues/didHandleURL(_:)``
- <doc:Logging>

### Customizing and Extending

- <doc:Extending>
- ``Appcues/experienceDelegate``
- ``Appcues/analyticsDelegate``
- ``Appcues/register(action:)``
- ``Appcues/register(trait:)``

### Checking Versions

- ``Appcues/version()-swift.method``
- ``Appcues/version()-swift.type.method`` 
