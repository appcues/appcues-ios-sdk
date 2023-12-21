//
//  ThemeProvider.swift
//  AppcuesKit
//
//  Created by Matt on 2023-11-02.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal protocol ThemeProviding: AnyObject {
    func theme(id: String?, completion: @escaping (Result<Theme?, Error>) -> Void)
}

@available(iOS 13.0, *)
internal class ThemeProvider: ThemeProviding {

    private let config: Appcues.Config
    private let networking: Networking

    var loadedThemes: [String: Theme] = [:]

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.networking = container.resolve(Networking.self)
    }

    func theme(id: String?, completion: @escaping (Result<Theme?, Error>) -> Void) {
        guard let id = id else { return completion(.success(nil)) }

        if let theme = loadedThemes[id] {
            completion(.success(theme))
        } else {
            load(themeID: id, completion: completion)
        }
    }

    private func load(themeID: String, completion: @escaping (Result<Theme?, Error>) -> Void) {
        let endpoint = ThemesEndpoint.theme(id: themeID)

        networking.get(from: endpoint, authorization: nil) { [weak self] (result: Result<Theme, Error>) in
            switch result {
            case .success(let theme):
                self?.loadedThemes[themeID] = theme
                completion(.success(theme))
            case .failure(let error):
                self?.config.logger.error("Loading theme %{public}@ failed with error %{public}@", themeID, "\(error)")
                completion(.failure(error))
            }
        }
    }
}
