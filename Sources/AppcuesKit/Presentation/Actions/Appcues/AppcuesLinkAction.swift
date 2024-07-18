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

    private weak var appcues: Appcues?

    var urlOpener: TopControllerGetting & URLOpening = UIApplication.shared

    let url: URL
    let openExternally: Bool

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        guard let config = configuration.decode(Config.self) else { return nil }
        self.url = config.url
        self.openExternally = config.openExternally ?? false
    }

    init(appcues: Appcues?, url: URL, openExternally: Bool = false) {
        self.appcues = appcues
        self.url = url
        self.openExternally = openExternally
    }

    func execute(completion: @escaping ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }
        let logger = appcues.config.logger

        // If a delegate is provided from the host application, preference is to use it for
        // handling navigation and invoking the completion handler.
        if let delegate = appcues.navigationDelegate {
            logger.info("@appcues/link: AppcuesNavigationDelegate opening %{private}@", url.absoluteString)
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
            let successfullyHandledUniversalLink = appcues.config.enableUniversalLinks
            && isAllowListed(url)
            && urlOpener.open(potentialUniversalLink: url)

            if successfullyHandledUniversalLink {
                logger.info("@appcues/link: universal link opened %{private}@", url.absoluteString)
                completion()
            } else {
                if openExternally {
                    logger.info("@appcues/link: external link opening %{private}@", url.absoluteString)
                    urlOpener.open(url, completionHandler: completion)
                } else {
                    logger.info("@appcues/link: in-app link opening %{private}@", url.absoluteString)
                    urlOpener.topViewController()?.present(SFSafariViewController(url: url), animated: true, completion: completion)
                }
            }
        } else {
            // Scheme link
            logger.info("@appcues/link: scheme link opening %{private}@", url.absoluteString)
            urlOpener.open(url, completionHandler: completion)
        }
    }

    private func isAllowListed(_ url: URL) -> Bool {
        guard let host = url.host, let hostAllowList = urlOpener.universalLinkHostAllowList else {
            // If no `AppcuesUniversalLinkHostAllowList` value in Info.plist, then all hosts are allowed.
            return true
        }

        return hostAllowList.contains(host)
    }
}
