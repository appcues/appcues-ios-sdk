fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios validate_code

```sh
[bundle exec] fastlane ios validate_code
```

Validate the code in the SDK repo works properly

### ios sdk_tests

```sh
[bundle exec] fastlane ios sdk_tests
```

Run SDK unit tests

### ios compile_cocoapods_example

```sh
[bundle exec] fastlane ios compile_cocoapods_example
```

Sanity check to make sure the cocoapods example app compiles

### ios compile_spm_example

```sh
[bundle exec] fastlane ios compile_spm_example
```

Sanity check to make sure the spm example app compiles

### ios prep_match

```sh
[bundle exec] fastlane ios prep_match
```

Setup code signing

### ios nuke_match

```sh
[bundle exec] fastlane ios nuke_match
```

Nuke code signing

### ios reset_match

```sh
[bundle exec] fastlane ios reset_match
```

Reset/renew code signing

### ios beta_example

```sh
[bundle exec] fastlane ios beta_example
```

Push example app to Testflight beta

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
