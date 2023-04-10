//
//  AppcuesLinkAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import SafariServices

@available(iOS 13.0, *)
internal class AppcuesLinkAction: AppcuesExperienceAction {
    struct Config: Decodable {
        let url: URL
        // swiftlint:disable:next discouraged_optional_boolean
        let openExternally: Bool?
    }

    static let type = "@appcues/link"

    var urlOpener: TopControllerGetting & URLOpening = UIApplication.shared

    let url: URL
    let openExternally: Bool

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.url = config.url
        self.openExternally = config.openExternally ?? false
    }

    init(url: URL, openExternally: Bool = false) {
        self.url = url
        self.openExternally = openExternally
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        // If a delegate is provided from the host application, preference is to use it for
        // handling navigation and invoking the completion handler.
        if let delegate = appcues.navigationDelegate {
            delegate.navigate(to: url, openExternally: openExternally) { _ in completion() }
            return
        }

        // If no delegate provided, fall back to automatic handling behavior provided by the
        // UIApplication - caveat, the completion callback may execute before the app has
        // fully navigated to the destination.

        let isWebLink = ["http", "https"].contains(url.scheme?.lowercased())

        // SFSafariViewController only supports HTTP and HTTPS URLs and crashes otherwise,
        // and scheme links crash the universal link opener, so check here to be sure we route safely.
        if isWebLink {
            // Check try opening the link as if it's a universal link, and if not,
            // then fall back to the desired in-app or external browser.
            let successfullyHandledUniversalLink = appcues.config.enableUniversalLinks && urlOpener.open(potentialUniversalLink: url)

            if successfullyHandledUniversalLink {
                completion()
            } else {
                if openExternally {
                    urlOpener.open(url, options: [:]) { _ in completion() }
                } else {
                    urlOpener.topViewController()?.present(SFSafariViewController(url: url), animated: true, completion: completion)
                }
            }
        } else {
            // Scheme link
            urlOpener.open(url, options: [:]) { _ in completion() }
        }
    }
}
