//
//  Networking+Endpoint.swift
//  Appcues
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

extension Networking {

    /// Endpoints in the Appcues API.
    enum Endpoint {
        case activity(accountID: String, userID: String)
        case custom(path: String)

        /// URL fragments that that are appended to the `Config.apiHost` to mkae the URL for a network request.
        var path: String {
            switch self {
            case let .activity(accountID, userID):
                return "/v1/accounts/\(accountID)/users/\(userID)/activity?sync=1"
            case let .custom(path):
                return path
            }
        }
    }
}
