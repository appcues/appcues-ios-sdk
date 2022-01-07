//
//  ExperienceLoader.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ExperienceLoading {
    func load(contentID: String)
}

internal class ExperienceLoader: ExperienceLoading {

    private let networking: Networking
    private let experienceRenderer: ExperienceRendering

    // TODO: pull style loader into here so that everything is resolve at render time
    // CSS loading temporary thing for now anyway

    init(container: DIContainer) {
        self.networking = container.resolve(Networking.self)
        self.experienceRenderer = container.resolve(ExperienceRendering.self)
    }

    func load(contentID: String) {
        networking.get(
            from: APIEndpoint.content(contentID: contentID)
        ) { [weak self] (result: Result<Flow, Error>) in
            switch result {
            case .success(let flow):
                self?.experienceRenderer.show(flow: flow)
            case .failure(let error):
                print(error)
            }
        }
    }
}
