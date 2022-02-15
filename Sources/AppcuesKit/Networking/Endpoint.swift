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
    case activity(userID: String, sync: Bool)
    case content(experienceID: String)
    case preview(experienceID: String)

    /// URL fragments that that are appended to the `Config.apiHost` to make the URL for a network request.
    func url(config: Appcues.Config, storage: DataStoring) -> URL? {
        guard var components = URLComponents(url: config.apiHost, resolvingAgainstBaseURL: false) else { return nil }

        switch self {
        case let .activity(userID, sync):
            components.path = "/v1/accounts/\(config.accountID)/users/\(userID)/activity"
            if sync {
                components.queryItems = [URLQueryItem(name: "sync", value: "1")]
            }
        case let .content(experienceID):
            components.path = "/v1/accounts/\(config.accountID)/users/\(storage.userID)/experience_content/\(experienceID)"
        case let .preview(experienceID):
            // note: preview does not contain the /users/{user_id} portion of the path
            components.path = "/v1/accounts/\(config.accountID)/experience_preview/\(experienceID)"
        }

        return components.url
    }
}

/// Endpoint in the Appcues CDN.
internal enum CDNEndpoint: Endpoint {
    case styles(styleID: String)

    func url(config: Appcues.Config, storage: DataStoring) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "fast.appcues.com"

        switch self {
        case let .styles(styleID):
            components.path = "/v1/accounts/\(config.accountID)/styles/\(styleID)"
        }

        return components.url
    }
}

internal protocol Endpoint {
    func url(config: Appcues.Config, storage: DataStoring) -> URL?
}
