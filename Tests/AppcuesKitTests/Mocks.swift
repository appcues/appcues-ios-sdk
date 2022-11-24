//
//  Mocks.swift
//  AppcuesKitTests
//
//  Created by Matt on 2022-03-21.
//  Copyright © 2022 Appcues. All rights reserved.
//

import XCTest
import UIKit
@testable import AppcuesKit

enum Mocks {
    class TestSubscriber: AnalyticsSubscribing {
        var trackedUpdates = 0
        var lastUpdate: TrackingUpdate?

        func track(update: TrackingUpdate) {
            trackedUpdates += 1
            lastUpdate = update
        }
    }

    class TestDecorator: AnalyticsDecorating {
        var decorations = 0

        func decorate(_ tracking: TrackingUpdate) -> TrackingUpdate {
            decorations += 1
            return tracking
        }
    }

    @available(iOS 13.0, *)
    class ContainerViewController: DefaultContainerViewController {
        // ExperienceStateMachine checks these values to avoid unnecessary lifecycle events,
        // and so we need to mock them to trigger the correct events

        var mockIsBeingPresented = false
        override var isBeingPresented: Bool { mockIsBeingPresented }

        var mockIsBeingDismissed = false
        override var isBeingDismissed: Bool { mockIsBeingDismissed }

        override func navigate(to pageIndex: Int, animated: Bool) {
            pageMonitor.set(currentPage: pageIndex)
        }
    }
}

extension Experience {
    static var mock: Experience {
        Experience(
            id: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
            name: "Mock Experience: Group with 3 steps, Single step",
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [],
            steps: [
                Experience.Step(
                    fixedID: "fb529214-3c78-4d6d-ba93-b55d22497ca1",
                    children: [
                        Step.Child(fixedID: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                        Step.Child(fixedID: "149f335f-15f6-4d8a-9e38-29a4ca435fd2"),
                        Step.Child(fixedID: "0c8eb697-8aa6-4eed-a291-69ed3aa85237")
                    ]
                ),
                .child(
                    Step.Child(fixedID: "03652bd5-f0cb-44f0-9274-e95b4441d857")
                )
            ],
            redirectURL: nil,
            nextContentID: "abc")
    }

    static var singleStepMock: Experience {
        Experience(
            id: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
            name: "Single step experience",
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [],
            steps: [
                Experience.Step(
                    fixedID: "fb529214-3c78-4d6d-ba93-b55d22497ca1",
                    children: [
                        Step.Child(fixedID: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                    ]
                )
            ],
            redirectURL: nil,
            nextContentID: nil)
    }

    static func mockWithForm(defaultValue: String?, attributeName: String?) -> Experience {
        Experience(
            id: UUID(uuidString: "ded7b50f-bc24-42de-a0fa-b1f10fc10d00")!,
            name: "Mock Experience: Single step with form",
            type: "mobile",
            publishedAt: 1632142800000,
            traits: [],
            steps: [
                Experience.Step(
                    fixedID: "02b83a13-537c-4cfc-89be-815e303d1c00",
                    children: [
                        Step.Child(formWithFixedID: "6cf396f6-1f01-4449-9e38-7e845f5316c0", defaultValue: defaultValue, attributeName: attributeName)
                    ]
                )
            ],
            redirectURL: nil,
            nextContentID: "abc")
    }
}

extension Experience.Step {
    init(fixedID: String, children: [Child]) {
        self = .group(Group(
            id: UUID(uuidString: fixedID) ?? UUID(),
            type: "group",
            children: children,
            traits: [],
            actions: [:]
        ))
    }
}

extension Experience.Step.Child {
    init(fixedID: String) {
        self.init(
            id: UUID(uuidString: fixedID) ?? UUID(),
            type: "modal",
            content: ExperienceComponent.spacer(ExperienceComponent.SpacerModel(id: UUID(), spacing: nil, style: nil)),
            traits: [],
            actions: [:]
        )
    }

    init(formWithFixedID fixedID: String, defaultValue: String?, attributeName: String?) {
        self.init(
            id: UUID(uuidString: fixedID) ?? UUID(),
            type: "modal",
            content: ExperienceComponent.textInput(ExperienceComponent.TextInputModel(
                id: UUID(uuidString: "f002dc4f-c5fc-4439-8916-0047a5839741")!,
                label: ExperienceComponent.TextModel(id: UUID(), text: "Form label", style: nil),
                errorLabel: nil,
                placeholder: nil,
                defaultValue: defaultValue,
                required: true,
                numberOfLines: nil,
                maxLength: nil,
                dataType: nil,
                textFieldStyle: nil,
                cursorColor: nil,
                attributeName: attributeName,
                style: nil)),
            traits: [],
            actions: [:]
        )
    }

}

extension ExperienceData {
    static var mock: ExperienceData { ExperienceData(.mock) }
    static var singleStepMock: ExperienceData { ExperienceData(.singleStepMock) }
    static func mockWithForm(defaultValue: String?, attributeName: String? = nil) -> ExperienceData {
        ExperienceData(.mockWithForm(defaultValue: defaultValue, attributeName: attributeName ))
    }

    @available(iOS 13.0, *)
    func package(presentExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil) -> ExperiencePackage {
        let containerController = Mocks.ContainerViewController(stepControllers: [UIViewController()], pageMonitor: PageMonitor(numberOfPages: 1, currentPage: 0))
        return ExperiencePackage(
            traitInstances: [],
            steps: self.steps[0].items,
            containerController: containerController,
            wrapperController: containerController,
            presenter: {
                containerController.mockIsBeingPresented = true
                containerController.lifecycleHandler?.containerWillAppear()
                containerController.lifecycleHandler?.containerDidAppear()
                containerController.mockIsBeingPresented = false
                presentExpectation?.fulfill()
                $0?()
            },
            dismisser: {
                containerController.mockIsBeingDismissed = true
                containerController.lifecycleHandler?.containerWillDisappear()
                containerController.lifecycleHandler?.containerDidDisappear()
                containerController.mockIsBeingDismissed = false
                dismissExpectation?.fulfill()
                $0?()
            })
    }
}
