//
//  ContentLoader.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ContentLoading: AnyObject {
    func load(
        experienceID: String,
        published: Bool,
        queryItems: [URLQueryItem],
        trigger: ExperienceTrigger
    ) async throws

    func loadPush(
        id: String,
        published: Bool,
        queryItems: [URLQueryItem]
    ) async throws
}

internal class ContentLoader: ContentLoading {

    private let config: Appcues.Config
    private let storage: DataStoring
    private let networking: Networking
    private let experienceRenderer: ExperienceRendering
    private let notificationCenter: NotificationCenter

    /// Store the experience ID loaded (only if previewing) so that it can be refreshed.
    private var lastPreviewExperienceID: String?
    private var lastPreviewQueryItems: [URLQueryItem]?

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.networking = container.resolve(Networking.self)
        self.experienceRenderer = container.resolve(ExperienceRendering.self)
        self.notificationCenter = container.resolve(NotificationCenter.self)

        notificationCenter.addObserver(self, selector: #selector(refreshPreview), name: .shakeToRefresh, object: nil)
    }

    func load(
        experienceID: String,
        published: Bool,
        queryItems: [URLQueryItem],
        trigger: ExperienceTrigger
    ) async throws {

        let endpoint = published ?
            APIEndpoint.content(experienceID: experienceID, queryItems: queryItems) :
            APIEndpoint.preview(experienceID: experienceID, queryItems: queryItems)

        do {
            let experience: Experience = try await networking.get(
                from: endpoint,
                authorization: Authorization(bearerToken: storage.userSignature)
            )

            try await experienceRenderer.processAndShow(
                experience: ExperienceData(experience, trigger: trigger, priority: .normal, published: published)
            )
        } catch {
            config.logger.error("Loading experience %{public}@ failed with error %{public}@", experienceID, "\(error)")
            throw error
        }

        lastPreviewExperienceID = published ? nil : experienceID
        lastPreviewQueryItems = published ? nil : queryItems
    }

    func loadPush(
        id: String,
        published: Bool,
        queryItems: [URLQueryItem]
    ) async throws {
        let endpoint = published ?
            APIEndpoint.pushContent(id: id) :
            APIEndpoint.pushPreview(id: id)

        let body = PushRequest(
            deviceID: storage.deviceID,
            queryItems: queryItems
        )

        let data = try? NetworkClient.encoder.encode(body)

        do {
            try await networking.post(
                to: endpoint,
                authorization: Authorization(bearerToken: storage.userSignature),
                body: data
            )
        } catch {
            config.logger.error("Loading push %{public}@ failed with error %{public}@", id, "\(error)")
            throw error
        }
    }

    @objc
    private func refreshPreview(notification: Notification) {
        guard let experienceID = lastPreviewExperienceID else { return }

        Task {
            try await load(experienceID: experienceID, published: false, queryItems: lastPreviewQueryItems ?? [], trigger: .preview)
        }
    }
}
