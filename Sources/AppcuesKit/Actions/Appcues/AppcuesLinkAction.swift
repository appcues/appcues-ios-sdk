//
//  AppcuesLinkAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import SafariServices

internal protocol URLOpening {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler: ((Bool) -> Void)?)
    func topViewController() -> UIViewController?
}

internal struct AppcuesLinkAction: ExperienceAction {
    static let type = "@appcues/link"

    var urlOpener: URLOpening = UIApplication.shared

    let url: URL
    let openExternally: Bool

    init?(config: [String: Any]?) {
        if let url = URL(string: config?["url"] as? String ?? "") {
            self.url = url
            self.openExternally = (config?["external"] as? Bool) ?? false
        } else {
            return nil
        }
    }

    func execute(inContext appcues: Appcues) {
        if openExternally {
            urlOpener.open(url, options: [:], completionHandler: nil)
        } else {
            urlOpener.topViewController()?.present(SFSafariViewController(url: url), animated: true)
        }
    }
}

extension UIApplication: URLOpening {}
