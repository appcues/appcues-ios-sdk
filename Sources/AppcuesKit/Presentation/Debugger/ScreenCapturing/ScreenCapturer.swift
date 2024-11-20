//
//  ScreenCapturer.swift
//  AppcuesKit
//
//  Created by James Ellis on 2/16/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal enum ScreenCaptureError: Error {
    case customerAPINotFound
    case noImageData
    case failedCaptureEncoding
}

internal class ScreenCapturer {
    private let config: Appcues.Config
    private let networking: Networking
    private let experienceRenderer: ExperienceRendering

    init(config: Appcues.Config, networking: Networking, experienceRenderer: ExperienceRendering) {
        self.config = config
        self.networking = networking
        self.experienceRenderer = experienceRenderer
    }

    @MainActor
    func captureScreen(window: UIWindow?, authorization: Authorization, captureUI: ScreenCaptureUI) async {
        if experienceRenderer.experienceData(forContext: .modal) != nil {
            try? await experienceRenderer.dismiss(inContext: .modal, markComplete: false)
        }

        guard let window = window,
              let screenshot = window.screenshot(),
              let layout = await Appcues.elementTargeting.captureLayout() else {
            let toast = DebugToast(message: .screenCaptureFailure, style: .failure)
            captureUI.showToast(toast)
            return
        }

        let timestamp = Date()
        var capture = Capture(
            appId: config.applicationID,
            displayName: window.screenCaptureDisplayName(),
            screenshotImageUrl: nil,
            layout: layout,
            metadata: Capture.Metadata(insets: Capture.Insets(window.safeAreaInsets)),
            timestamp: timestamp,
            screenshot: screenshot
        )

        captureUI.showConfirmation(screen: capture) { [weak self] result in
            guard let self = self else { return }

            if case let .success(name) = result {
                // get updated name
                capture.displayName = name

                Task {
                    // save the screen into the account/app
                    await self.saveScreen(captureUI: captureUI, capture: capture, authorization: authorization)
                }
            }
        }
    }

    @MainActor
    private func saveScreen(captureUI: ScreenCaptureUI, capture: Capture, authorization: Authorization) async {
        do {
            try await saveScreenCapture(networking: networking, screen: capture, authorization: authorization)

            let toast = DebugToast(message: .screenCaptureSuccess(displayName: capture.displayName), style: .success)
            captureUI.showToast(toast)
        } catch NetworkingError.nonSuccessfulStatusCode(400, _) {
            let toast = DebugToast(message: .captureSessionExpired, style: .failure, duration: 6.0)
            captureUI.showToast(toast)
        } catch {
            let toast = DebugToast(message: .screenUploadFailure, style: .failure, duration: 6.0) {
                // onRetry - recursively call save to try again
                Task {
                    await self.saveScreen(captureUI: captureUI, capture: capture, authorization: authorization)
                }
            }
            captureUI.showToast(toast)
        }
    }

    private func saveScreenCapture(
        networking: Networking,
        screen: Capture,
        authorization: Authorization
    ) async throws {
        // this is a 4-step chain of nested async completion blocks

        // Step 1 - lookup customer API endpoint in from settings endpoint
        let sdkSettings: SdkSettings = try await networking.get(from: SettingsEndpoint.settings, authorization: nil)

        guard let customerAPIHost = URL(string: sdkSettings.services.customerApi) else {
            throw ScreenCaptureError.customerAPINotFound
        }

        // Step 2 - call pre-upload endpoint and get pre-signed image upload URL
        let upload: ScreenshotUpload = try await networking.post(
            to: CustomerAPIEndpoint.preSignedImageUpload(host: customerAPIHost, filename: "\(screen.id).png"),
            authorization: authorization,
            body: nil,
            requestId: nil
        )
        // Step 3 - upload the image using the pre-signed image upload URL
        guard let imageData = screen.screenshot.pngData() else {
            throw ScreenCaptureError.noImageData
        }

        try await networking.put(
            to: URLEndpoint(url: upload.upload.presignedUrl),
            authorization: nil, // pre-signed url, no auth needed on upload
            body: imageData,
            contentType: "image/png"
        )

        // update the screenshotImageUrl on the screen we are capturing
        // return the transformed screen - with new screenshotImageUrl
        var updatedScreen = screen
        updatedScreen.screenshotImageUrl = upload.url

        // Step 4 - save the screen into the customer Appcues account
        guard let screenData = try? NetworkClient.encoder.encode(updatedScreen) else {
            throw ScreenCaptureError.failedCaptureEncoding
        }

        // this will ultimately resolve the initial completion handler that started this
        // chain of requests, with either success or failure of saving the full screen capture information
        try await networking.post(
            to: CustomerAPIEndpoint.screenCapture(host: customerAPIHost),
            authorization: authorization,
            body: screenData
        )
    }
}
