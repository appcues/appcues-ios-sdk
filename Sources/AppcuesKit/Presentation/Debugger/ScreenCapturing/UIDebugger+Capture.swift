//
//  UIDebugger+Capture.swift
//  AppcuesKit
//
//  Created by James Ellis on 2/16/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

internal enum ScreenCaptureError: Error {
    case customerAPINotFound
    case noImageData
    case noSelf
    case noImageURL
    case failedCaptureEncoding
}

@available(iOS 13.0, *)
extension UIDebugger {

    func saveScreenCapture(networking: Networking,
                           screen: Capture,
                           authorization: Authorization,
                           completion: @escaping (Result<Void, Error>) -> Void) {

        // this is a 4-step chain of nested async completion blocks
        // each step will execute and call on to the next, if successful, or bubble up error if not

        // start the chain by looking up the customer API path
        getCustomerAPIHost(networking: networking, screen: screen, authorization: authorization, completion: completion)
    }

    // 1. service discovery -> customer API
    private func getCustomerAPIHost(networking: Networking,
                                    screen: Capture,
                                    authorization: Authorization,
                                    completion: @escaping (Result<Void, Error>) -> Void) {
        networking.get(from: SettingsEndpoint.settings,
                       authorization: nil) { [weak self] (result: Result<SdkSettings, Error>) -> Void in

            switch result {
            case let .success(response):
                guard let self else {
                    completion(.failure(ScreenCaptureError.noSelf))
                    return
                }

                guard let customerAPIHost = URL(string: response.services.customerApi) else {
                    completion(.failure(ScreenCaptureError.customerAPINotFound))
                    return
                }

                // then call step 2
                self.getImageUploadURL(networking: networking,
                                       customerAPIHost: customerAPIHost,
                                       screen: screen,
                                       authorization: authorization,
                                       completion: completion)

            case let .failure(error):
                // bubble up error
                completion(.failure(error))
            }
        }
    }

    // 2. pre-upload -> presignedUrl
    private func getImageUploadURL(networking: Networking,
                                   customerAPIHost: URL,
                                   screen: Capture,
                                   authorization: Authorization,
                                   completion: @escaping (Result<Void, Error>) -> Void) {
        networking.post(to: CustomerAPIEndpoint.preSignedImageUpload(host: customerAPIHost, filename: "\(screen.id).png"),
                        authorization: authorization,
                        body: nil,
                        requestId: nil) { [weak self] (result: Result<ScreenshotUpload, Error>) -> Void in

            guard let self else {
                completion(.failure(ScreenCaptureError.noSelf))
                return
            }

            switch result {
            case let .success(response):
                // then call step 3
                self.uploadImage(networking: networking,
                                 customerAPIHost: customerAPIHost,
                                 screen: screen,
                                 authorization: authorization,
                                 upload: response,
                                 completion: completion)

            case let .failure(error):
                // bubble up error
                completion(.failure(error))
            }

        }
    }

    // 3. upload image
    private func uploadImage(networking: Networking,
                             customerAPIHost: URL,
                             screen: Capture,
                             authorization: Authorization,
                             upload: ScreenshotUpload,
                             completion: @escaping (Result<Void, Error>) -> Void) {

        guard let imageData = screen.screenshot.pngData() else {
            completion(.failure(ScreenCaptureError.noImageData))
            return
        }

        networking.put(to: URLEndpoint(url: URL(string: upload.upload.presignedUrl)),
                       authorization: nil, // pre-signed url, no auth needed on upload
                       body: imageData,
                       contentType: "image/png") { [weak self] result in

            guard let self else {
                completion(.failure(ScreenCaptureError.noSelf))
                return
            }

            switch result {
            case .success:
                // then call step 4
                self.saveScreen(networking: networking,
                                customerAPIHost: customerAPIHost,
                                screen: screen,
                                authorization: authorization,
                                upload: upload,
                                completion: completion)

            case let .failure(error):
                // bubble up error
                completion(.failure(error))
            }
        }
    }

    // 4. save screen - final step
    private func saveScreen(networking: Networking,
                            customerAPIHost: URL,
                            screen: Capture,
                            authorization: Authorization,
                            upload: ScreenshotUpload,
                            completion: @escaping (Result<Void, Error>) -> Void) {
        guard let screenshotImageUrl = URL(string: upload.url) else {
            completion(.failure(ScreenCaptureError.noImageURL))
            return
        }

        var screen = screen
        screen.screenshotImageUrl = screenshotImageUrl

        guard let data = try? NetworkClient.encoder.encode(screen) else {
            completion(.failure(ScreenCaptureError.failedCaptureEncoding))
            return
        }

        // this will ultimately resolve the initial completion handler that started this
        // chain of requests, with either success or failure of saving the full screen capture information
        networking.post(to: CustomerAPIEndpoint.screenCapture(host: customerAPIHost),
                        authorization: authorization,
                        body: data,
                        completion: completion)

    }

}
