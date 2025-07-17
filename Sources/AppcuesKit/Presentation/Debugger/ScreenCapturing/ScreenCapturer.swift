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

@available(iOS 13.0, *)
internal class ScreenCapturer {
    private let config: Appcues.Config
    private let networking: Networking
    private let experienceRenderer: ExperienceRendering

    init(config: Appcues.Config, networking: Networking, experienceRenderer: ExperienceRendering) {
        self.config = config
        self.networking = networking
        self.experienceRenderer = experienceRenderer
    }

    func captureScreen(window: UIWindow?, authorization: Authorization, captureUI: ScreenCaptureUI) {
        guard experienceRenderer.experienceData(forContext: .modal) == nil else {
            experienceRenderer.dismiss(inContext: .modal, markComplete: false) { _ in
                self.captureScreen(window: window, authorization: authorization, captureUI: captureUI)
            }
            return
        }

        Task {
            await doCapture(window: window, authorization: authorization, captureUI: captureUI)
        }
    }

    @MainActor
    private func doCapture(window: UIWindow?, authorization: Authorization, captureUI: ScreenCaptureUI) async {
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

                // save the screen into the account/app
                self.saveScreen(captureUI: captureUI, capture: capture, authorization: authorization)
            }
        }
    }

    private func saveScreen(captureUI: ScreenCaptureUI, capture: Capture, authorization: Authorization) {
        saveScreenCapture(networking: networking, screen: capture, authorization: authorization) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    let toast = DebugToast(message: .screenCaptureSuccess(displayName: capture.displayName), style: .success)
                    captureUI.showToast(toast)
                }
            case .failure(NetworkingError.nonSuccessfulStatusCode(400, _)):
                DispatchQueue.main.async {
                    let toast = DebugToast(message: .captureSessionExpired, style: .failure, duration: 6.0)
                    captureUI.showToast(toast)
                }
            case .failure:
                DispatchQueue.main.async {
                    let toast = DebugToast(message: .screenUploadFailure, style: .failure, duration: 6.0) {
                        // onRetry - recursively call save to try again
                        self.saveScreen(captureUI: captureUI, capture: capture, authorization: authorization)
                    }
                    captureUI.showToast(toast)
                }
            }
        }
    }

    private func saveScreenCapture(
        networking: Networking,
        screen: Capture,
        authorization: Authorization,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // this is a 4-step chain of nested async completion blocks

        // Step 1 - lookup customer API endpoint in from settings endpoint
        networking.get(from: SettingsEndpoint.settings, authorization: nil) { (result: Result<SdkSettings, Error>) -> Void in

            switch result {

            // step 1 failure - bubble up error
            case let .failure(error): completion(.failure(error))

            // step 1 success
            case let .success(response):
                guard let customerAPIHost = URL(string: response.services.customerApi) else {
                    completion(.failure(ScreenCaptureError.customerAPINotFound))
                    return
                }

                // Step 2 - call pre-upload endpoint and get pre-signed image upload URL
                networking.post(
                    to: CustomerAPIEndpoint.preSignedImageUpload(host: customerAPIHost, filename: "\(screen.id).png"),
                    authorization: authorization,
                    body: nil,
                    requestId: nil
                ) { (result: Result<ScreenshotUpload, Error>) -> Void in

                    switch result {

                    // step 2 failure - bubble up error
                    case let .failure(error): completion(.failure(error))

                    // step 2 success
                    case let .success(response):

                        // Step 3 - upload the image using the pre-signed image upload URL
                        self.uploadImage(networking: networking, screen: screen, upload: response) { result in
                            switch result {

                            // step 3 failure - bubble up error
                            case let .failure(error): completion(.failure(error))

                            // step 3 success
                            case let .success(screen): // screen value here is now updated with screenshotImageUrl

                                // Step 4 - save the screen into the customer Appcues account
                                self.saveScreen(
                                    networking: networking,
                                    customerAPIHost: customerAPIHost,
                                    screen: screen,
                                    authorization: authorization,
                                    completion: completion // final completion here will go back to caller of saveScreenCapture
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func uploadImage(
        networking: Networking,
        screen: Capture,
        upload: ScreenshotUpload,
        completion: @escaping (Result<Capture, Error>) -> Void
    ) {
        guard let imageData = screen.screenshot.pngData() else {
            completion(.failure(ScreenCaptureError.noImageData))
            return
        }

        // update the screenshotImageUrl on the screen we are capturing
        // this will be returned in completion handler if the upload succeeds
        var screen = screen
        screen.screenshotImageUrl = upload.url

        networking.put(
            to: URLEndpoint(url: upload.upload.presignedUrl),
            authorization: nil, // pre-signed url, no auth needed on upload
            body: imageData,
            contentType: "image/png"
        ) { result in

            switch result {
            case .success:
                // return the transformed screen - with new screenshotImageUrl
                completion(.success(screen))

            case let .failure(error):
                // bubble up error
                completion(.failure(error))
            }
        }
    }

    private func saveScreen(
        networking: Networking,
        customerAPIHost: URL,
        screen: Capture,
        authorization: Authorization,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let data = try? NetworkClient.encoder.encode(screen) else {
            completion(.failure(ScreenCaptureError.failedCaptureEncoding))
            return
        }

        // this will ultimately resolve the initial completion handler that started this
        // chain of requests, with either success or failure of saving the full screen capture information
        networking.post(
            to: CustomerAPIEndpoint.screenCapture(host: customerAPIHost),
            authorization: authorization,
            body: data,
            completion: completion
        )
    }
}
