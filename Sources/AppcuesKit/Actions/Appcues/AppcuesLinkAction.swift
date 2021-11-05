//
//  AppcuesLinkAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit
import SafariServices

internal struct AppcuesLinkAction: ExperienceAction {
    static let type = "@appcues/link"

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
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.topViewController()?.present(SFSafariViewController(url: url), animated: true)
        }
    }
}
