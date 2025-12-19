//
//  SocketActivityProcessor.swift
//  AppcuesKit
//
//  Created by Appcues on 2025-01-XX.
//  Copyright © 2025 Appcues. All rights reserved.
//

import Foundation

/// WebSocket-based activity processor using Phoenix channels instead of REST API.
@available(iOS 13.0, *)
internal class SocketActivityProcessor: ActivityProcessing, PhoenixChannelDelegate {

    private let config: Appcues.Config
    private let storage: DataStoring
    private let phoenixChannel: PhoenixChannel

    // Track pending qualify requests by ref -> (requestID, completion handler)
    private var pendingQualifyRequests: [String: (UUID, (Result<QualifyResponse, Error>) -> Void)] =
        [:]

    // Track requests currently being processed
    private var processingItems: Set<UUID> = []

    private let syncQueue = DispatchQueue(label: "appcues-socket-activity-processor")

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        self.phoenixChannel = PhoenixChannel(container: container)
        self.phoenixChannel.delegate = self
    }

    func process(
        _ activity: Activity, completion: @escaping (Result<QualifyResponse, Error>) -> Void
    ) {
        guard let activityStorage = ActivityStorage(activity) else { return }

        syncQueue.sync {
            // Mark current item as processing
            processingItems.insert(activity.requestID)
        }

        // Ensure socket is connected before processing
        ensureConnected { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                // Send current activity only - no retry logic for socket mode
                // If socket is disconnected, fail fast and let caller handle it
                self.handleQualify(activity: activityStorage, completion: completion)
            case .failure(let error):
                self.syncQueue.sync {
                    self.processingItems.remove(activityStorage.requestID)
                }
                completion(.failure(error))
            }
        }
    }

    // MARK: - PhoenixChannelDelegate

    func phoenixChannel(
        _ channel: PhoenixChannel, didReceiveReply ref: String, payload: [String: Any]
    ) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            // Find matching pending request by ref
            guard let (requestID, completion) = self.pendingQualifyRequests[ref] else {
                // No matching request, might be a join reply or other event
                return
            }

            self.pendingQualifyRequests.removeValue(forKey: ref)

            // Try to decode as SocketQualifyResponse
            do {
                let data = try JSONSerialization.data(withJSONObject: payload)
                let decoder = NetworkClient.decoder
                let socketResponse = try decoder.decode(SocketQualifyResponse.self, from: data)
                let qualifyResponse = socketResponse.toQualifyResponse()

                self.processingItems.remove(requestID)
                completion(.success(qualifyResponse))
            } catch {
                self.config.logger.error("Failed to decode socket reply: %{public}@", "\(error)")
                self.processingItems.remove(requestID)
                completion(.failure(error))
            }
        }
    }

    func phoenixChannel(_ channel: PhoenixChannel, didReceiveError error: Error) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            // Complete any pending requests with error
            for (ref, (requestID, completion)) in self.pendingQualifyRequests {
                self.pendingQualifyRequests.removeValue(forKey: ref)
                self.processingItems.remove(requestID)
                completion(.failure(error))
            }
        }
    }

    // MARK: - Private Methods

    private func ensureConnected(completion: @escaping (Result<Void, Error>) -> Void) {
        let accountID = config.accountID
        let userID = storage.userID

        guard !userID.isEmpty else {
            completion(
                .failure(
                    NSError(
                        domain: "SocketActivityProcessor", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "No user ID"])))
            return
        }

        // Connect will check if already connected to same topic
        phoenixChannel.connect(accountID: accountID, userID: userID, completion: completion)
    }

    private func handleQualify(
        activity: ActivityStorage, completion: @escaping (Result<QualifyResponse, Error>) -> Void
    ) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }

            // Decode activity and send via socket - let PhoenixChannel generate the ref
            do {
                let activityDict =
                    try JSONSerialization.jsonObject(with: activity.data) as? [String: Any] ?? [:]
                let ref = self.phoenixChannel.sendEvent(event: "event", payload: activityDict)

                guard !ref.isEmpty else {
                    self.processingItems.remove(activity.requestID)
                    completion(
                        .failure(
                            NSError(
                                domain: "SocketActivityProcessor", code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Failed to send event - not connected"
                                ])))
                    return
                }

                // Store completion handler with the ref returned by PhoenixChannel
                self.pendingQualifyRequests[ref] = (activity.requestID, completion)
            } catch {
                self.processingItems.remove(activity.requestID)
                completion(.failure(error))
            }
        }
    }

    /// Connect socket (called on identify)
    func connect(
        accountID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        phoenixChannel.connect(accountID: accountID, userID: userID, completion: completion)
    }

    /// Leave channel but keep socket alive for reuse (called on reset)
    func disconnect() {
        phoenixChannel.leaveChannelOnly()
        syncQueue.sync {
            pendingQualifyRequests.removeAll()
            processingItems.removeAll()
        }
    }
}
