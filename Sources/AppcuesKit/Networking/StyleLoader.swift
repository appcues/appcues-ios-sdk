//
//  StyleLoader.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// Manage styles associated with flows.
///
/// A flow step group includes a style ID that can be used to look up the style properties for the associated theme.
internal class StyleLoader {

    // MARK: Model
    struct Style: Decodable {
        let globalStyling: String
    }

    // MARK: Dependencies
    private let networking: Networking

    // MARK: Data
    var cachedStyles: [String: Style] = [:]

    init(container: DIContainer) {
        self.networking = container.resolve(Networking.self)
    }

    func fetch(styleID: String, _ completion: @escaping (Result<Style, Error>) -> Void) {
        if let cachedStyle = cachedStyles[styleID] {
            completion(.success(cachedStyle))
            return
        }

        networking.get(
            from: Networking.CDNEndpoint.styles(styleID: styleID)
        ) { [weak self] (result: Result<Style, Error>) in
            switch result {
            case .success(let style):
                self?.cachedStyles[styleID] = style
            case .failure:
                break
            }

            // Call completion from main thread to ensure consistency with returning cached data.
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
