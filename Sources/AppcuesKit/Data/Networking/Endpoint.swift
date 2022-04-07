//
//  Endpoint.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// Endpoints in the Appcues API.
internal enum APIEndpoint: Endpoint {
    case activity(userID: String)
    case qualify(userID: String)
    case content(experienceID: String)
    case preview(experienceID: String)
    case health

    /// URL fragments that that are appended to the `Config.apiHost` to make the URL for a network request.
    func url(config: Appcues.Config, storage: DataStoring) -> URL? {
        guard var components = URLComponents(url: config.apiHost, resolvingAgainstBaseURL: false) else { return nil }

        switch self {
        case let .activity(userID):
            components.path = "/v1/accounts/\(config.accountID)/users/\(userID)/activity"
        case let .qualify(userID):
            components.path = "/v1/accounts/\(config.accountID)/users/\(userID)/qualify"
        case let .content(experienceID):
            components.path = "/v1/accounts/\(config.accountID)/users/\(storage.userID)/experience_content/\(experienceID)"
        case let .preview(experienceID):
            // optionally include the userID, if one exists, to allow for a personalized preview capability
            if storage.userID.isEmpty {
                components.path = "/v1/accounts/\(config.accountID)/experience_preview/\(experienceID)"
            } else {
                components.path = "/v1/accounts/\(config.accountID)/users/\(storage.userID)/experience_preview/\(experienceID)"
            }
        case .health:
            components.path = "/healthz"
        }

        return components.url
    }
}

internal protocol Endpoint {
    func url(config: Appcues.Config, storage: DataStoring) -> URL?
}
