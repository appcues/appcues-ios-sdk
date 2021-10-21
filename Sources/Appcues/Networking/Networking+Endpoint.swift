//
//  Networking+Endpoint.swift
//  Appcues
//
//  Created by Matt on 2021-10-08.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol Endpoint {
    func url(with config: Config) -> URL?
}

extension Networking {

    /// Endpoints in the Appcues API.
    enum APIEndpoint: Endpoint {
        case activity(accountID: String, userID: String)
        case content(accountID: String, userID: String, contentID: String)
        case custom(path: String)

        /// URL fragments that that are appended to the `Config.apiHost` to make the URL for a network request.
        func url(with config: Config) -> URL? {
            var components = URLComponents()
            components.scheme = "https"
            components.host = config.apiHost

            switch self {
            case let .activity(accountID, userID):
                components.path = "/v1/accounts/\(accountID)/users/\(userID)/activity"
                components.queryItems = [URLQueryItem(name: "sync", value: "1")]
            case let .content(accountID, userID, contentID):
                components.path = "/v1/accounts/\(accountID)/users/\(userID)/content/\(contentID)"
            case let .custom(path):
                components.path = path
            }

            return components.url
        }
    }

    /// Endpoint in the Appcues CDN.
    enum CDNEndpoint: Endpoint {
        case styles(accountID: String, styleID: String)

        func url(with config: Config) -> URL? {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "fast.appcues.com"

            switch self {
            case let .styles(accountID, styleID):
                components.path = "/v1/accounts/\(accountID)/styles/\(styleID)"
            }

            return components.url
        }
    }
}
