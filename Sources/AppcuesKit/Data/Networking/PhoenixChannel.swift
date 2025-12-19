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
// swiftlint:disable:next type_body_length
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
    private var reconnectScheduled = false

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

        // If already connected or connecting to the same topic, just call completion
        if (isConnected || isConnecting) && currentTopic == topic {
            // If still connecting, queue the completion to be called when join completes
            if isConnecting, let existingCompletion = pendingJoinCompletion {
                pendingJoinCompletion = { result in
                    existingCompletion(result)
                    completion(result)
                }
            } else {
                completion(.success(()))
            }
            return
        }

        // Clear reconnection flag
        reconnectScheduled = false

        // If we have an existing socket and are connected to a different topic,
        // leave the old channel first, then join the new one on the same socket
        if let existingSocket = webSocketTask, isConnected, let oldTopic = currentTopic,
            oldTopic != topic
        {
            // Leave old channel first
            leaveChannel()
            currentTopic = topic
            isConnected = false
            isConnecting = true
            pendingJoinCompletion = completion
            joinChannel(topic: topic)
            return
        }

        // If we have a socket but aren't connected, it might be dead
        // Recreate it to be safe (URLSessionWebSocketTask doesn't expose connection state)
        if webSocketTask != nil {
            // Clean up potentially dead socket
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
            // Fall through to create a new socket
        }

        // No existing socket - create a new one
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

    /// Leave the current channel but keep the socket connection alive for reuse
    func leaveChannelOnly() {
        reconnectScheduled = false

        let wasConnected = isConnected
        isConnected = false
        isConnecting = false
        stopHeartbeat()

        // Leave the channel if we were connected
        if wasConnected, webSocketTask != nil {
            leaveChannel()
        }

        // Clear state but keep socket alive
        currentTopic = nil
        joinRef = nil
        pendingJoinCompletion = nil
    }

    /// Disconnect from the socket completely
    func disconnect() {
        // Clear reconnection flag and topic to prevent reconnection
        reconnectScheduled = false
        currentTopic = nil

        disconnectInternal()
    }

    private func disconnectInternal() {
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
        }

        let message: [Any] = [ref, ref, topic, "phx_join", joinPayload]

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

        let ref = nextRef()
        let message: [Any] = [joinRef, ref, topic, "phx_leave", [:]]
        sendMessage(message)
    }

    private func startHeartbeat() {
        stopHeartbeat()

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
                if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 && self.isConnecting {
                    return
                }

                // Clean up dead socket - server closed the connection
                self.webSocketTask?.cancel(with: .goingAway, reason: nil)
                self.webSocketTask = nil

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
        guard let data = text.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
            json.count >= 5,
            let ref = json[1] as? String,
            let topic = json[2] as? String,
            let event = json[3] as? String,
            let payload = json[4] as? [String: Any]
        else {
            return
        }

        // joinRef is json[0] - can be null or a string, we don't need it for parsing

        // Handle phoenix system topic messages (like heartbeat responses)
        if topic == "phoenix" {
            if event == "phx_reply", let pendingHeartbeatRef = pendingHeartbeatRef,
                ref == pendingHeartbeatRef
            {
                self.pendingHeartbeatRef = nil
                heartbeatTimeoutTimer?.invalidate()
                heartbeatTimeoutTimer = nil
            }
            return
        }

        // Ignore messages for topics we're not currently connected to (stale messages)
        guard topic == currentTopic else {
            return
        }

        switch event {
        case "phx_reply":
            // Check if this is a join reply
            if ref == joinRef {
                if let status = payload["status"] as? String, status == "ok" {
                    // Join successful
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
            // Server closed the channel - clean up socket and reconnect
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
            isConnected = false
            joinRef = nil
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

            webSocketTask.send(.string(string)) { [weak self] error in
                if let error = error {
                    self?.config.logger.error(
                        "PHOENIX: Send failed - %{public}@",
                        error.localizedDescription
                    )
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
        // Don't schedule if already scheduled, no topic, or already connected
        guard currentTopic != nil, !isConnected, !reconnectScheduled else { return }

        reconnectScheduled = true

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            guard let self = self else { return }

            self.reconnectScheduled = false

            // Check if still need to reconnect
            guard self.currentTopic != nil, !self.isConnected else { return }

            let accountID = self.config.accountID
            let userID = self.storage.userID

            guard !userID.isEmpty else { return }

            self.connect(accountID: accountID, userID: userID) { _ in }
        }
    }

    private func nextRef() -> String {
        messageRef += 1
        return String(messageRef)
    }
}
