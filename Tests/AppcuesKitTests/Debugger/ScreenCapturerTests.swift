//
//  ScreenCapturerTests.swift
//  AppcuesKitTests
//
//  Created by Matt on 2023-10-16.
//  Copyright © 2023 Appcues. All rights reserved.
//

import XCTest
@testable import AppcuesKit

class ScreenCapturerTests: XCTestCase {

    private var screenCapturer: ScreenCapturer!
    private var networking: MockNetworking!
    private var experienceRenderer: MockExperienceRenderer!
    private var screenCaptureUI: MockScreenCaptureUI!

    let authorization = Authorization(bearerToken: "token")!
    let sdkSettingsSuccess = SdkSettings(services: SdkSettings.Services(customerApi: "https://customerapi.appcues.com"))
    let preUploadSuccess = ScreenshotUpload(
        upload: ScreenshotUpload.Upload(presignedUrl: URL(string: "https://appcues.com/presigned-url")!),
        url: URL(string: "https://appcues.com/image-url")!
    )

    override func setUpWithError() throws {
        Appcues.elementTargeting = MockElementTargeting()

        networking = MockNetworking()
        experienceRenderer = MockExperienceRenderer()
        screenCaptureUI = MockScreenCaptureUI()

        screenCapturer = ScreenCapturer(
            config: MockAppcues().config,
            networking: networking,
            experienceRenderer: experienceRenderer)
    }

    @MainActor
    func testVisibleExperiencesAreDismissed() async throws {
        // Arrange
        var experienceDismissed = false
        experienceRenderer.onExperienceData = { context in
            XCTAssertEqual(context, .modal)
            return experienceDismissed ? nil : ExperienceData.mock
        }

        experienceRenderer.onDismiss = { context, markComplete in
            XCTAssertEqual(context, .modal)
            XCTAssertFalse(markComplete)

            experienceDismissed = true
        }

        // Act
        await screenCapturer.captureScreen(window: nil, authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        XCTAssertTrue(experienceDismissed)
    }

    @MainActor
    func testInitialFailure() async throws {
        // Arrange
        var toast: DebugToast?
        screenCaptureUI.onShowToast = { toast = $0 }

        // Act
        // nil window should cause failure
        await screenCapturer.captureScreen(window: nil, authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        let unwrappedToast = try XCTUnwrap(toast)
        XCTAssertEqual(unwrappedToast.message, .screenCaptureFailure)
        XCTAssertEqual(unwrappedToast.style, .failure)
    }

    @MainActor
    func testConfirmationScreenShows() async throws {
        // Arrange
        let confirmationShownExpectation = expectation(description: "Confirmation screen shows")
        screenCaptureUI.onShowConfirmation = { capture, completion in
            confirmationShownExpectation.fulfill()
        }

        // Act
        await screenCapturer.captureScreen(window: UIWindow(), authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        await fulfillment(of: [confirmationShownExpectation], timeout: 1)
    }

    // Step 1 failure
    @MainActor
    func testSaveSDKSettingsFail() async throws {
        // Arrange
        // Step 1
        networking.onGet = { endpoint, authorization in
            guard case SettingsEndpoint.settings = endpoint else { return XCTFail("Unexpected GET request") }
            throw NetworkingError.nonSuccessfulStatusCode(500, nil)
        }

        // Simulate trigger the interaction to submit
        screenCaptureUI.onShowConfirmation = { _, completion in completion(.success("Screen Name")) }

        let failureToastShownExpectation = expectation(description: "Toast shown")
        screenCaptureUI.onShowToast = { toast in
            XCTAssertEqual(toast.message, .screenUploadFailure)
            XCTAssertEqual(toast.style, .failure)
            failureToastShownExpectation.fulfill()
        }

        // Act
        await screenCapturer.captureScreen(window: UIWindow(), authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        await fulfillment(of: [failureToastShownExpectation], timeout: 1)
    }

    // Step 2 failure
    @MainActor
    func testSavePreUploadFail() async throws {
        // Arrange
        // Step 1
        networking.onGet = { endpoint, authorization in
            guard case SettingsEndpoint.settings = endpoint else { return XCTFail("Unexpected GET request") }
            XCTAssertNil(authorization)
            return self.sdkSettingsSuccess
        }

        // Step 2
        networking.onPost = { endpoint, authorization, data, requestID in
            guard case CustomerAPIEndpoint.preSignedImageUpload = endpoint else { return XCTFail("Unexpected POST request") }
            throw NetworkingError.nonSuccessfulStatusCode(500, nil)
        }

        // Simulate trigger the interaction to submit
        screenCaptureUI.onShowConfirmation = { _, completion in completion(.success("Screen Name")) }

        let failureToastShownExpectation = expectation(description: "Toast shown")
        screenCaptureUI.onShowToast = { toast in
            XCTAssertEqual(toast.message, .screenUploadFailure)
            XCTAssertEqual(toast.style, .failure)
            failureToastShownExpectation.fulfill()
        }

        // Act
        await screenCapturer.captureScreen(window: UIWindow(), authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        await fulfillment(of: [failureToastShownExpectation], timeout: 1)
    }

    // Step 3 failure
    @MainActor
    func testSaveUploadImageFail() async throws {
        // Arrange
        // Step 1
        networking.onGet = { endpoint, authorization in
            guard case SettingsEndpoint.settings = endpoint else { return XCTFail("Unexpected GET request") }
            XCTAssertNil(authorization)
            return self.sdkSettingsSuccess
        }

        // Step 2
        networking.onPost = { endpoint, authorization, data, requestID in
            guard case let CustomerAPIEndpoint.preSignedImageUpload(host, _) = endpoint else { return XCTFail("Unexpected POST request") }
            XCTAssertEqual(self.authorization, authorization)
            XCTAssertEqual(host.absoluteString, "https://customerapi.appcues.com")
            return self.preUploadSuccess
        }

        // Step 3
        networking.onPutEmptyResponse = { endpoint, authorization, data, contentType in
            switch endpoint {
            case is URLEndpoint:
                throw NetworkingError.nonSuccessfulStatusCode(500, nil)
            default:
                XCTFail("Unexpected PUT request")
            }
        }

        // Simulate trigger the interaction to submit
        screenCaptureUI.onShowConfirmation = { _, completion in completion(.success("Screen Name")) }

        let failureToastShownExpectation = expectation(description: "Toast shown")
        screenCaptureUI.onShowToast = { toast in
            XCTAssertEqual(toast.message, .screenUploadFailure)
            XCTAssertEqual(toast.style, .failure)
            failureToastShownExpectation.fulfill()
        }

        // Act
        await screenCapturer.captureScreen(window: UIWindow(), authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        await fulfillment(of: [failureToastShownExpectation], timeout: 1)
    }

    // Step 4 failure
    @MainActor
    func testSaveScreenFail() async throws {
        // Arrange
        // Step 1
        networking.onGet = { endpoint, authorization in
            guard case SettingsEndpoint.settings = endpoint else { return XCTFail("Unexpected GET request") }
            XCTAssertNil(authorization)
            return self.sdkSettingsSuccess
        }

        // Step 2
        networking.onPost = { endpoint, authorization, data, requestID in
            guard case let CustomerAPIEndpoint.preSignedImageUpload(host, _) = endpoint else { return XCTFail("Unexpected POST request") }
            XCTAssertEqual(self.authorization, authorization)
            XCTAssertEqual(host.absoluteString, "https://customerapi.appcues.com")
            return self.preUploadSuccess
        }

        // Step 3
        networking.onPutEmptyResponse = { endpoint, authorization, data, contentType in
            guard case let urlEndpoint as URLEndpoint = endpoint else { return XCTFail("Unexpected PUT request") }
            XCTAssertNil(authorization)
            XCTAssertEqual(urlEndpoint.url.absoluteString, "https://appcues.com/presigned-url")
            XCTAssertNotNil(data)
            XCTAssertEqual(contentType, "image/png")
        }

        // Step 4
        networking.onPostEmptyResponse = { endpoint, authorization, data in
            guard case CustomerAPIEndpoint.screenCapture = endpoint else { return XCTFail("Unexpected POST request") }
            throw NetworkingError.nonSuccessfulStatusCode(500, nil)
        }

        // Simulate trigger the interaction to submit
        screenCaptureUI.onShowConfirmation = { _, completion in completion(.success("Screen Name")) }

        let failureToastShownExpectation = expectation(description: "Toast shown")
        screenCaptureUI.onShowToast = { toast in
            XCTAssertEqual(toast.message, .screenUploadFailure)
            XCTAssertEqual(toast.style, .failure)
            failureToastShownExpectation.fulfill()
        }

        // Act
        await screenCapturer.captureScreen(window: UIWindow(), authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        await fulfillment(of: [failureToastShownExpectation], timeout: 1)
    }

    // Step 4 success
    @MainActor
    func testSaveSuccess() async throws {
        // Arrange
        // Step 1
        networking.onGet = { endpoint, authorization in
            guard case SettingsEndpoint.settings = endpoint else { return XCTFail("Unexpected GET request") }
            XCTAssertNil(authorization)
            return self.sdkSettingsSuccess
        }

        // Step 2
        networking.onPost = { endpoint, authorization, data, requestID in
            guard case let CustomerAPIEndpoint.preSignedImageUpload(host, _) = endpoint else { return XCTFail("Unexpected POST request") }
            XCTAssertEqual(self.authorization, authorization)
            XCTAssertEqual(host.absoluteString, "https://customerapi.appcues.com")
            return self.preUploadSuccess
        }

        // Step 3
        networking.onPutEmptyResponse = { endpoint, authorization, data, contentType in
            guard case let urlEndpoint as URLEndpoint = endpoint else { return XCTFail("Unexpected PUT request") }
            XCTAssertNil(authorization)
            XCTAssertEqual(urlEndpoint.url.absoluteString, "https://appcues.com/presigned-url")
            XCTAssertNotNil(data)
            XCTAssertEqual(contentType, "image/png")
        }

        // Step 4
        networking.onPostEmptyResponse = { endpoint, authorization, data in
            guard case let CustomerAPIEndpoint.screenCapture(host) = endpoint else { return XCTFail("Unexpected POST request") }
            XCTAssertEqual(self.authorization, authorization)
            XCTAssertEqual(host.absoluteString, "https://customerapi.appcues.com")
        }

        // Simulate trigger the interaction to submit
        screenCaptureUI.onShowConfirmation = { _, completion in completion(.success("Screen Name")) }

        let successToastShownExpectation = expectation(description: "Toast shown")
        screenCaptureUI.onShowToast = { toast in
            XCTAssertEqual(toast.message, .screenCaptureSuccess(displayName: "Screen Name"))
            XCTAssertEqual(toast.style, .success)
            successToastShownExpectation.fulfill()
        }

        // Act
        await screenCapturer.captureScreen(window: UIWindow(), authorization: authorization, captureUI: screenCaptureUI)

        // Assert
        await fulfillment(of: [successToastShownExpectation], timeout: 1)
    }
}

private class MockScreenCaptureUI: ScreenCaptureUI {
    var onShowConfirmation: ((Capture, (Result<String, Error>) -> Void) -> Void)?
    func showConfirmation(screen: Capture, completion: @escaping (Result<String, Error>) -> Void) {
        onShowConfirmation?(screen, completion)
    }

    var onShowToast: ((DebugToast) -> Void)?
    func showToast(_ toast: DebugToast) {
        onShowToast?(toast)
    }
}

private class MockElementTargeting: AppcuesElementTargeting {
    func captureLayout() async -> AppcuesViewElement? {
        AppcuesViewElement(x: 0, y: 0, width: 10, height: 10, type: "mock", selector: nil, children: nil)
    }

    func inflateSelector(from properties: [String : String]) -> AppcuesKit.AppcuesElementSelector? {
        nil
    }
}
