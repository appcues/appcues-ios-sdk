# ``AppcuesKit/AppcuesNavigationDelegate``

The `AppcuesNavigationDelegate` provides a method to execute link handling and a completion block to call when the link navigation has fully completed.

## Usage

The implementation of ``AppcuesNavigationDelegate/navigate(to:openExternally:)`` must handle all links, not just in-app deep links.

For regular web links, the `openExternally` parameter indicates if the link is intended to open in the default web browser or an in-app browser.

```swift
class SampleNavigationDelegate: AppcuesNavigationDelegate {
    func navigate(to url: URL, openExternally: Bool) async {

        // Check if the url is a deep link that should perform in-app navigation.
        if isDeepLink(url) {
            await handleDeepLink(url, completion: completion)
        } else {
            if openExternally {
                // Open the URL in the default web browser.
                await UIApplication.shared.open(url, options: [:])
            } else {
                // Show a SFSafariViewController. `topViewController` needs to be determined.
                await withCheckedContinuation { continuation in
                    topViewController.present(SFSafariViewController(url: url), animated: true) {
                        continuation.resume()
                    }
                }
            }
        }
    }

    private func isDeepLink(_ url: URL) -> Bool {
        // TODO: return true if the url is a deep link that should perform in-app navigation.
        return true
    }

    private func handleDeepLink(_ url: URL) async {
        // TODO: perform in-app navigation and call the completion block once navigation is completed.
        await withCheckedContinuation { continuation in
            present(DestinationViewController(), animated: true) {
                continuation.resume()
            }
        }
    }
}

// Must store a strong reference because Appcues.navigationDelegate is `weak`.
let appcuesNavigationDelegate = SampleNavigationDelegate()

appcuesInstance.navigationDelegate = appcuesNavigationDelegate
```

## Topics

### Handing Navigation

- ``AppcuesNavigationDelegate/navigate(to:openExternally:)``
