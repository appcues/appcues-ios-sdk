//
//  StyleLoader.swift
//  Appcues
//
//  Created by Matt on 2021-10-15.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import Combine

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

    var subscriptions = Set<AnyCancellable>()

    init(networking: Networking) {
        self.networking = networking
    }

    func fetch(styleID: String) -> AnyPublisher<Style, Error> {
        if let cachedStyle = cachedStyles[styleID] {
            return Result.Publisher(cachedStyle).eraseToAnyPublisher()
        }

        let publisher: AnyPublisher<Style, Error> = networking.get(
            from: Networking.CDNEndpoint.styles(accountID: networking.config.accountID, styleID: styleID)
        )

        publisher.sink { completion in
            completion.printIfError()
        } receiveValue: { [weak self] style in
            self?.cachedStyles[styleID] = style
        }
        .store(in: &subscriptions)

        // Return publisher on main thread to ensure consistency with returning cached data.
        return publisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
