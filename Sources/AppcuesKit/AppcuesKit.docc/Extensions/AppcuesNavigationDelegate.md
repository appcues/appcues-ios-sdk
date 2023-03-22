# ``AppcuesKit/AppcuesNavigationDelegate``

The `AppcuesNavigationDelegate` provides a method to execute link handling and a completion block to call when the link navigation has fully completed.

## Usage

The implementation of ``AppcuesNavigationDelegate/navigate(to:openExternally:completion:)`` must handle all links, not just in-app deep links.

For regular web links, the `openExternally` parameter indicates if the link is intended to open in the default web browser or an in-app browser.

```swift
class SampleNavigationDelegate: AppcuesNavigationDelegate {
    func navigate(to url: URL, openExternally: Bool, completion: @escaping (Bool) -> Void) {

        // Check if the url is a deep link that should perform in-app navigation.
        if isDeepLink(url) {
            handleDeepLink(url, completion: completion)
        } else {
            if openExternally {
                // Open the URL in the default web browser.
                UIApplication.shared.open(url, options: [:]) { success in completion(success) }
            } else {
                // Show a SFSafariViewController. `topViewController` needs to be determined.
                topViewController.present(SFSafariViewController(url: url), animated: true) { completion(true) }
            }
        }
    }

    private func isDeepLink(_ url: URL) -> Bool {
        // TODO: return true if the url is a deep link that should perform in-app navigation.
        return true
    }

    private func handleDeepLink(_ url: URL, completion: @escaping (Bool) -> Void) {
        // TODO: perform in-app navigation and call the completion block once navigation is completed.
        present(DestinationViewController(), animated: true, completion: completion)
    }
}

// Must store a strong reference because Appcues.navigationDelegate is `weak`.
let appcuesNavigationDelegate = SampleNavigationDelegate()

appcuesInstance.navigationDelegate = appcuesNavigationDelegate
```

## Topics

### Handing Navigation

- ``AppcuesNavigationDelegate/navigate(to:openExternally:completion:)``
