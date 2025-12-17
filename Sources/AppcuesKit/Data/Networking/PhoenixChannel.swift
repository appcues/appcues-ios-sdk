//
//  PhoenixChannel.swift
//  AppcuesKit
//
//  Created by Appcues on 2025-01-XX.
//  Copyright © 2025 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal protocol PhoenixChannelDelegate: AnyObject {
    func phoenixChannel(
        _ channel: PhoenixChannel, didReceiveReply ref: String, payload: [String: Any])
    func phoenixChannel(_ channel: PhoenixChannel, didReceiveError error: Error)
}

/// Phoenix channel client implementing Phoenix protocol v2.0.0
@available(iOS 13.0, *)
internal class PhoenixChannel {
    weak var delegate: PhoenixChannelDelegate?

    private let config: Appcues.Config
    private let storage: DataStoring
    private let urlSession: URLSession

    private var webSocketTask: URLSessionWebSocketTask?
    private var heartbeatTimer: Timer?
    private var currentTopic: String?
    private var joinRef: String?
    private var pendingJoinCompletion: ((Result<Void, Error>) -> Void)?
    private var isConnected = false
    private var isConnecting = false
    private var messageRef: UInt64 = 0
    private var pendingHeartbeatRef: String?
    private var heartbeatTimeoutTimer: Timer?
    private var reconnectWorkItem: DispatchWorkItem?

    private let heartbeatInterval: TimeInterval = 30.0
    private let heartbeatTimeout: TimeInterval = 10.0

    init(container: DIContainer) {
        self.config = container.resolve(Appcues.Config.self)
        self.storage = container.resolve(DataStoring.self)
        // Use the WebSocket-specific URLSession with proper timeout configuration
        self.urlSession = config.webSocketURLSession
    }

    deinit {
        disconnect()
    }

    /// Connect to the Phoenix socket and join a channel
    func connect(
        accountID: String, userID: String, completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let topic = "sdk:\(accountID):\(userID)"

        // If already connected to the same topic, just call completion
        if isConnected && currentTopic == topic {
            completion(.success(()))
            return
        }

        // Cancel any pending reconnection attempts
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil

        // Disconnect existing connection if any
        disconnectInternal()

        currentTopic = topic

        // Build socket URL
        guard
            var components = URLComponents(
                url: config.socketHost, resolvingAgainstBaseURL: false)
        else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }
        components.path = "/v1/socket/websocket"
        components.queryItems = [URLQueryItem(name: "vsn", value: "2.0.0")]

        guard let socketURL = components.url else {
            completion(.failure(NetworkingError.invalidURL))
            return
        }

        // Create WebSocket task
        config.logger.debug("PHOENIX: Connecting to %{public}@", socketURL.absoluteString)
        let task = urlSession.webSocketTask(with: socketURL)
        webSocketTask = task

        // Start receiving messages and connect
        receiveMessage()
        task.resume()

        // Join channel
        isConnected = false
        isConnecting = true
        pendingJoinCompletion = completion
        joinChannel(topic: topic)
    }

    /// Disconnect from the socket
    func disconnect() {
        // Cancel any pending reconnection
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil

        disconnectInternal()

        // Clear topic to prevent reconnection
        currentTopic = nil
    }

    private func disconnectInternal() {
        config.logger.debug("PHOENIX: Disconnecting (isConnected=%{public}@)", String(isConnected))

        let wasConnected = isConnected
        isConnected = false
        isConnecting = false
        stopHeartbeat()

        // Only try to leave if we were actually connected and have a socket
        if wasConnected, webSocketTask != nil {
            leaveChannel()
        }

        // Cancel and clean up WebSocket
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        // Don't clear currentTopic - we need it for reconnection
        // Only clear it in disconnect() which is called explicitly
        joinRef = nil
        pendingJoinCompletion = nil
    }

    /// Send an event to the channel
    @discardableResult
    func sendEvent(event: String, payload: [String: Any], ref: String? = nil) -> String {
        guard let topic = currentTopic, let joinRef = joinRef, isConnected else {
            config.logger.error(
                "PHOENIX: Cannot send event '%{public}@' - channel not joined. topic=%{public}@, joinRef=%{public}@, isConnected=%{public}@",
                event,
                currentTopic ?? "nil",
                self.joinRef ?? "nil",
                String(isConnected)
            )

            // Trigger reconnection if we have a topic but aren't connected
            if currentTopic != nil && !isConnected {
                config.logger.debug(
                    "PHOENIX: Triggering reconnection due to send attempt while disconnected")
                scheduleReconnect()
            }

            return ""
        }

        let usedRef = ref ?? nextRef()
        let message: [Any] = [joinRef, usedRef, topic, event, payload]
        sendMessage(message)

        return usedRef
    }

    // MARK: - Private Methods

    private func joinChannel(topic: String) {
        let ref = nextRef()
        joinRef = ref

        var joinPayload: [String: Any] = [
            "response_format": "v2"
        ]

        // Add token if available
        if let token = storage.userSignature {
            joinPayload["token"] = token
            config.logger.debug("PHOENIX: Joining with authentication token")
        } else {
            config.logger.debug("PHOENIX: Joining without authentication token")
        }

        let message: [Any] = [ref, ref, topic, "phx_join", joinPayload]

        config.logger.debug("PHOENIX: Attempting to join channel %{public}@", topic)

        // Set up timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
            guard let self = self else { return }
            if self.joinRef == ref, let completion = self.pendingJoinCompletion {
                // Timeout - join didn't complete
                self.config.logger.error("PHOENIX: Join timeout for channel %{public}@", topic)
                self.joinRef = nil
                self.pendingJoinCompletion = nil
                completion(
                    .failure(
                        NSError(
                            domain: "PhoenixChannel", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Join timeout"])))
            }
        }

        sendMessage(message) { [weak self] result in
            guard let self = self else { return }
            if case .failure(let error) = result, let completion = self.pendingJoinCompletion {
                self.config.logger.error(
                    "PHOENIX: Failed to send join message: %{public}@", "\(error)")
                self.joinRef = nil
                self.pendingJoinCompletion = nil
                completion(.failure(error))
            }
        }
    }

    private func leaveChannel() {
        guard let topic = currentTopic, let joinRef = joinRef, webSocketTask != nil else {
            return
        }

        config.logger.debug("PHOENIX: Leaving channel %{public}@", topic)
        let ref = nextRef()
        let message: [Any] = [joinRef, ref, topic, "phx_leave", [:]]
        sendMessage(message)
    }

    private func startHeartbeat() {
        stopHeartbeat()

        config.logger.debug(
            "PHOENIX: Starting heartbeat timer (interval=%{public}f seconds)", heartbeatInterval)

        // Create timer on main thread to ensure it fires
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let timer = Timer.scheduledTimer(
                withTimeInterval: self.heartbeatInterval, repeats: true
            ) { [weak self] _ in
                self?.sendHeartbeat()
            }

            // Add to run loop with common modes so it works during scrolling, etc.
            RunLoop.main.add(timer, forMode: .common)
            self.heartbeatTimer = timer

            // Don't send first heartbeat immediately - wait for the timer interval
        }
    }

    private func stopHeartbeat() {
        config.logger.debug("PHOENIX: Stopping heartbeat timer")

        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer?.invalidate()
            self?.heartbeatTimer = nil
            self?.heartbeatTimeoutTimer?.invalidate()
            self?.heartbeatTimeoutTimer = nil
            self?.pendingHeartbeatRef = nil
        }
    }

    private func sendHeartbeat() {
        guard isConnected, webSocketTask != nil else { return }

        // If there's a pending heartbeat that hasn't been acknowledged, connection might be dead
        if pendingHeartbeatRef != nil {
            config.logger.error("PHOENIX: Heartbeat timeout - previous heartbeat not acknowledged")
            isConnected = false
            joinRef = nil
            scheduleReconnect()
            return
        }

        let ref = nextRef()
        config.logger.debug("PHOENIX: Sending heartbeat with ref=%{public}@", ref)

        // Phoenix heartbeat goes to the "phoenix" topic with empty joinRef
        let message: [Any] = ["", ref, "phoenix", "heartbeat", [:] as [String: Any]]

        sendMessage(message) { [weak self] result in
            guard let self = self else { return }
            if case .failure(let error) = result {
                self.config.logger.error(
                    "PHOENIX: Failed to send heartbeat: %{public}@", "\(error)")
                self.isConnected = false
                self.joinRef = nil
                self.scheduleReconnect()
            }
        }

        pendingHeartbeatRef = ref

        // Set timeout for heartbeat response on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let timer = Timer.scheduledTimer(
                withTimeInterval: self.heartbeatTimeout, repeats: false
            ) { [weak self] _ in
                guard let self = self else { return }
                if self.pendingHeartbeatRef != nil {
                    self.config.logger.error("PHOENIX: Heartbeat response timeout")
                    self.isConnected = false
                    self.joinRef = nil
                    self.pendingHeartbeatRef = nil
                    self.scheduleReconnect()
                }
            }

            RunLoop.main.add(timer, forMode: .common)
            self.heartbeatTimeoutTimer = timer
        }
    }

    @available(iOS 13.0, *)
    private func receiveMessage() {
        guard let webSocketTask = webSocketTask else {
            return
        }
        webSocketTask.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // Continue receiving
                self.receiveMessage()

            case .failure(let error):
                let nsError = error as NSError
                self.config.logger.error(
                    "PHOENIX: WebSocket receive error - domain=%{public}@, code=%{public}d, message=%{public}@",
                    nsError.domain,
                    nsError.code,
                    error.localizedDescription
                )

                // Ignore cancelled errors - these are expected during disconnect/reconnect
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    return
                }

                // Ignore POSIX error 57 (Socket is not connected) during connection phase
                // This is a transient error that occurs during WebSocket handshake
                if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
                    if self.isConnecting {
                        self.config.logger.debug(
                            "PHOENIX: Ignoring transient socket error during connection")
                        return
                    }
                }

                // Mark as disconnected
                self.isConnected = false
                self.isConnecting = false
                self.joinRef = nil

                self.delegate?.phoenixChannel(self, didReceiveError: error)
                // Attempt reconnection
                self.scheduleReconnect()
            }
        }
    }

    private func handleMessage(_ text: String) {
        // Log the raw message for debugging
        config.logger.debug("PHOENIX: Raw message: %{private}@", text)

        guard let data = text.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
            json.count >= 5,
            let ref = json[1] as? String,
            let topic = json[2] as? String,
            let event = json[3] as? String,
            let payload = json[4] as? [String: Any]
        else {
            config.logger.debug("PHOENIX: Invalid message format: %{private}@", text)
            return
        }

        // joinRef is json[0] - can be null or a string, we don't need it for parsing

        // Handle phoenix system topic messages (like heartbeat responses)
        if topic == "phoenix" {
            if event == "phx_reply" {
                // Check if this is a heartbeat reply
                if let pendingHeartbeatRef = pendingHeartbeatRef, ref == pendingHeartbeatRef {
                    config.logger.debug("PHOENIX: Heartbeat acknowledged (ref=%{public}@)", ref)
                    self.pendingHeartbeatRef = nil
                    heartbeatTimeoutTimer?.invalidate()
                    heartbeatTimeoutTimer = nil
                }
            }
            return
        }

        // Ignore messages for topics we're not currently connected to (stale messages)
        guard topic == currentTopic else {
            config.logger.debug(
                "PHOENIX: Ignoring message for stale topic %{public}@ (current: %{public}@)", topic,
                currentTopic ?? "nil")
            return
        }

        // Ignore stale error responses (from old connections/joinRefs)
        if event == "phx_reply",
            let status = payload["status"] as? String, status == "error",
            let response = payload["response"] as? [String: Any],
            let reason = response["reason"] as? String, reason == "unmatched topic"
        {
            config.logger.debug(
                "PHOENIX: Ignoring stale 'unmatched topic' error for ref=%{public}@", ref)
            return
        }

        config.logger.debug(
            "PHOENIX: Received %{public}@ on %{public}@ (ref=%{public}@)", event, topic, ref)

        switch event {
        case "phx_reply":
            // Check if this is a join reply
            if ref == joinRef {
                if let status = payload["status"] as? String, status == "ok" {
                    // Join successful
                    config.logger.debug("PHOENIX: Successfully joined channel %{public}@", topic)
                    isConnected = true
                    isConnecting = false
                    if let completion = pendingJoinCompletion {
                        pendingJoinCompletion = nil
                        startHeartbeat()
                        completion(.success(()))
                    }
                    if let response = payload["response"] as? [String: Any] {
                        delegate?.phoenixChannel(self, didReceiveReply: ref, payload: response)
                    }
                } else {
                    // Join failed
                    let reason = payload["response"] as? String ?? "Join failed"
                    config.logger.error(
                        "PHOENIX: Join failed for channel %{public}@: %{public}@", topic, reason)
                    isConnecting = false
                    if let completion = pendingJoinCompletion {
                        pendingJoinCompletion = nil
                        completion(
                            .failure(
                                NSError(
                                    domain: "PhoenixChannel", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: reason])))
                    }
                }
            } else if let response = payload["response"] as? [String: Any] {
                // Regular reply - pass to delegate
                delegate?.phoenixChannel(self, didReceiveReply: ref, payload: response)
            }

        case "phx_error":
            // Try to extract error message from various possible formats
            let errorMessage: String
            if let reason = payload["reason"] as? String {
                errorMessage = reason
            } else if let response = payload["response"] as? [String: Any],
                let reason = response["reason"] as? String
            {
                errorMessage = reason
            } else {
                errorMessage = "Unknown error: \(payload)"
            }

            config.logger.error(
                "PHOENIX: Error from server (ref=%{public}@): %{public}@", ref, errorMessage)

            // If this is an error on the join ref, the join failed
            if ref == joinRef {
                config.logger.error(
                    "PHOENIX: Join error - channel rejected: %{public}@", errorMessage)
                isConnected = false
                joinRef = nil

                // Don't reconnect if it's an authentication error
                if errorMessage.contains("unauthorized") || errorMessage.contains("auth") {
                    config.logger.error("PHOENIX: Authentication error - not reconnecting")
                    if let completion = pendingJoinCompletion {
                        pendingJoinCompletion = nil
                        completion(
                            .failure(
                                NSError(
                                    domain: "PhoenixChannel", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                } else {
                    scheduleReconnect()
                }
            }

            let error = NSError(
                domain: "PhoenixChannel", code: -1,
                userInfo: [NSLocalizedDescriptionKey: errorMessage])
            delegate?.phoenixChannel(self, didReceiveError: error)

        case "phx_close":
            config.logger.debug("PHOENIX: Channel closed")
            scheduleReconnect()

        default:
            // Unknown event, pass to delegate
            delegate?.phoenixChannel(self, didReceiveReply: ref, payload: payload)
        }
    }

    private func sendMessage(_ message: [Any], completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let webSocketTask = webSocketTask else {
            config.logger.error("PHOENIX: Cannot send message - no WebSocket task")
            completion?(.failure(NetworkingError.invalidURL))
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            let string = String(data: data, encoding: .utf8) ?? ""
            config.logger.debug("PHOENIX: Sending %{private}@", string)

            webSocketTask.send(.string(string)) { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    let nsError = error as NSError
                    self.config.logger.error(
                        "PHOENIX: Send failed - domain=%{public}@, code=%{public}d, message=%{public}@",
                        nsError.domain,
                        nsError.code,
                        error.localizedDescription
                    )

                    // Check if this is a socket disconnection error
                    if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
                        // Socket is not connected - mark as disconnected and trigger reconnection
                        self.config.logger.error(
                            "PHOENIX: Socket disconnected, triggering reconnection")
                        self.isConnected = false
                        self.joinRef = nil
                        self.scheduleReconnect()
                    }

                    completion?(.failure(error))
                } else {
                    completion?(.success(()))
                }
            }
        } catch {
            config.logger.error("PHOENIX: Failed to serialize message: %{public}@", "\(error)")
            completion?(.failure(error))
        }
    }

    private func scheduleReconnect() {
        // Don't schedule multiple reconnections
        guard currentTopic != nil, !isConnected else { return }

        config.logger.debug("PHOENIX: Scheduling reconnection in 5 seconds")

        // Simple reconnection - in production you'd want exponential backoff
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            guard let self = self, self.currentTopic != nil, !self.isConnected else { return }

            let accountID = self.config.accountID
            let userID = self.storage.userID

            if !userID.isEmpty {
                self.config.logger.debug("PHOENIX: Attempting reconnection")
                self.connect(accountID: accountID, userID: userID) { result in
                    switch result {
                    case .success:
                        self.config.logger.debug("PHOENIX: Reconnection successful")
                    case .failure(let error):
                        self.config.logger.error(
                            "PHOENIX: Reconnection failed: %{public}@", "\(error)")
                    }
                }
            }
        }
    }

    private func nextRef() -> String {
        messageRef += 1
        return String(messageRef)
    }
}
