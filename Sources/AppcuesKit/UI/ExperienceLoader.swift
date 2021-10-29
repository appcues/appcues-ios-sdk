//
//  ExperienceLoader.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal class ExperienceLoader {

    private let networking: Networking
    private let config: Appcues.Config
    private let storage: Storage
    private let flowRenderer: FlowRenderer

    // TODO: pull style loader into here so that everything is resolve at render time
    // CSS loading temporary thing for now anyway

    init(container: DIContainer) {
        self.networking = container.resolve(Networking.self)
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(Storage.self)
        self.flowRenderer = container.resolve(FlowRenderer.self)
    }

    func load(contentID: String) {
        // TODO: move config and storage dependency down into networking so it does not need passed in everywhere
        networking.get(
            from: Networking.APIEndpoint.content(accountID: config.accountID, userID: storage.userID, contentID: contentID)
        ) { [weak self] (result: Result<Flow, Error>) in
            switch result {
            case .success(let flow):
                self?.flowRenderer.show(flow: flow)
            case .failure(let error):
                print(error)
            }
        }
    }
}
