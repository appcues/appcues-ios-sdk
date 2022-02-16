fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios validate_code
```
fastlane ios validate_code
```
Validate the code in the SDK repo works properly
### ios sdk_tests
```
fastlane ios sdk_tests
```
Run SDK unit tests
### ios compile_cocoapods_example
```
fastlane ios compile_cocoapods_example
```
Sanity check to make sure the cocoapods example app compiles
### ios compile_spm_example
```
fastlane ios compile_spm_example
```
Sanity check to make sure the spm example app compiles
### ios beta_example
```
fastlane ios beta_example
```
Push example app to Testflight beta

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
