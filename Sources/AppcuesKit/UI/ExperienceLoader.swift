//
//  ExperienceLoader.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ExperienceLoading {
    func load(contentID: String, published: Bool)
}

internal class ExperienceLoader: ExperienceLoading {

    private let networking: Networking
    private let experienceRenderer: ExperienceRendering

    init(container: DIContainer) {
        self.networking = container.resolve(Networking.self)
        self.experienceRenderer = container.resolve(ExperienceRendering.self)
    }

    func load(contentID: String, published: Bool) {

        let endpoint = published ?
            APIEndpoint.content(contentID: contentID) :
            APIEndpoint.preview(contentID: contentID)

        networking.get(
            from: endpoint
        ) { [weak self] (result: Result<Experience, Error>) in
            switch result {
            case .success(let experience):
                self?.experienceRenderer.show(experience: experience, published: published)
            case .failure(let error):
                print(error)
            }
        }
    }
}
