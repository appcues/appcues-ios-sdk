//
//  ExperienceLoader.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal protocol ExperienceLoading: AnyObject {
    func load(experienceID: String, published: Bool, completion: ((Result<Void, Error>) -> Void)?)
}

@available(iOS 13.0, *)
internal class ExperienceLoader: ExperienceLoading {

    private let config: Appcues.Config
    private let networking: Networking
    private let experienceRenderer: ExperienceRendering
    private let notificationCenter: NotificationCenter

    /// Store the experience ID loaded (only if previewing) so that it can be refreshed.
    private var lastPreviewExperienceID: String?

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.networking = container.resolve(Networking.self)
        self.experienceRenderer = container.resolve(ExperienceRendering.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)

        notificationCenter.addObserver(self, selector: #selector(refreshPreview), name: .shakeToRefresh, object: nil)
    }

    func load(experienceID: String, published: Bool, completion: ((Result<Void, Error>) -> Void)?) {

        let endpoint = published ?
            APIEndpoint.content(experienceID: experienceID) :
            APIEndpoint.preview(experienceID: experienceID)

        networking.get(
            from: endpoint
        ) { [weak self] (result: Result<Experience, Error>) in
            switch result {
            case .success(let experience):
                self?.experienceRenderer.show(
                    experience: ExperienceData(experience, priority: .normal, published: published),
                    completion: completion)
            case .failure(let error):
                self?.config.logger.error("Loading experience %{public}s failed with error %{public}s", experienceID, "\(error)")
                completion?(.failure(error))
            }

            self?.lastPreviewExperienceID = published ? nil : experienceID
        }
    }

    @objc
    private func refreshPreview(notification: Notification) {
        guard let experienceID = lastPreviewExperienceID else { return }

        load(experienceID: experienceID, published: false, completion: nil)
    }
}
