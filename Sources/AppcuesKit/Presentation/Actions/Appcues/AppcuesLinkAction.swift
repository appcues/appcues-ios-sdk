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
internal class AppcuesLinkAction: ExperienceAction {
    static let type = "@appcues/link"

    var urlOpener: TopControllerGetting & URLOpening = UIApplication.shared

    let url: URL
    let openExternally: Bool

    required init?(config: [String: Any]?) {
        if let url = URL(string: config?["url"] as? String ?? "") {
            self.url = url
            self.openExternally = (config?["openExternally"] as? Bool) ?? false
        } else {
            return nil
        }
    }

    init(url: URL, openExternally: Bool = false) {
        self.url = url
        self.openExternally = openExternally
    }

    func execute(inContext appcues: Appcues, completion: @escaping ActionRegistry.Completion) {
        // SFSafariViewController only supports HTTP and HTTPS URLs and crashes otherwise, so check to be safe.
        if !openExternally && ["http", "https"].contains(url.scheme?.lowercased()) {
            urlOpener.topViewController()?.present(SFSafariViewController(url: url), animated: true, completion: completion)
        } else {
            urlOpener.open(url, options: [:]) { _ in completion() }
        }
    }
}
