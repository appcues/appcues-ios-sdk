//
//  Networking+Endpoint.swift
//  Appcues
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol Endpoint {
    func url(config: Appcues.Config, storage: Storage) -> URL?
}

extension Networking {

    /// Endpoints in the Appcues API.
    enum APIEndpoint: Endpoint {
        case activity
        case content(contentID: String)
        case custom(path: String)

        /// URL fragments that that are appended to the `Config.apiHost` to make the URL for a network request.
        func url(config: Appcues.Config, storage: Storage) -> URL? {
            var components = URLComponents()
            components.scheme = "https"
            components.host = config.apiHost

            switch self {
            case .activity:
                components.path = "/v1/accounts/\(storage.accountID)/users/\(storage.userID)/activity"
                components.queryItems = [URLQueryItem(name: "sync", value: "1")]
            case let .content(contentID):
                components.path = "/v1/accounts/\(storage.accountID)/users/\(storage.userID)/content/\(contentID)"
            case let .custom(path):
                components.path = path
            }

            return components.url
        }
    }

    /// Endpoint in the Appcues CDN.
    enum CDNEndpoint: Endpoint {
        case styles(styleID: String)

        func url(config: Appcues.Config, storage: Storage) -> URL? {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "fast.appcues.com"

            switch self {
            case let .styles(styleID):
                components.path = "/v1/accounts/\(storage.accountID)/styles/\(styleID)"
            }

            return components.url
        }
    }
}
