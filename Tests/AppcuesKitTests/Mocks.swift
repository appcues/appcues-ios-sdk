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
            context: Context(
                localeId: "en",
                localeName: "English",
                workflowId: nil,
                workflowTaskId: nil
            ),
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
            nextContentID: "abc",
            renderContext: .modal)
    }

    static var mockFromWorkflow: Experience {
        Experience(
            id: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
            name: "Single step experience",
            type: "mobile",
            publishedAt: 1632142800000,
            context: Context(
                localeId: "en",
                localeName: "English",
                workflowId: "c2e376fb-f7ba-4d0c-bf87-1c7cfd1f5a94",
                workflowTaskId: "b16d3d86-9299-4bcd-9a04-e2a18d9c9a33"
            ),
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
            nextContentID: nil,
            renderContext: .modal)
    }

    static var singleStepMock: Experience {
        Experience(
            id: UUID(uuidString: "54b7ec71-cdaf-4697-affa-f3abd672b3cf")!,
            name: "Single step experience",
            type: "mobile",
            publishedAt: 1632142800000,
            context: nil,
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
            nextContentID: nil,
            renderContext: .modal)
    }

    static func mockWithForm(defaultValue: String?, attributeName: String?) -> Experience {
        Experience(
            id: UUID(uuidString: "ded7b50f-bc24-42de-a0fa-b1f10fc10d00")!,
            name: "Mock Experience: Single step with form",
            type: "mobile",
            publishedAt: 1632142800000,
            context: nil,
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
            nextContentID: "abc",
            renderContext: .modal)
    }

    static func mockWithStepActions(actions: [Experience.Action]) -> Experience {
        Experience(
            id: UUID(uuidString: "ded7b50f-bc24-42de-a0fa-b1f10fc10d00")!,
            name: "Mock Experience: actions on second group",
            type: "mobile",
            publishedAt: 1632142800000,
            context: nil,
            traits: [],
            steps: [
                Experience.Step(
                    fixedID: "fb529214-3c78-4d6d-ba93-b55d22497ca1",
                    children: [
                        Step.Child(fixedID: "e03ae132-91b7-4cb0-9474-7d4a0e308a07"),
                    ],
                    actions: ["fb529214-3c78-4d6d-ba93-b55d22497ca1" : actions]
                ),
                Experience.Step(
                    fixedID: "149f335f-15f6-4d8a-9e38-29a4ca435fd2",
                    children: [
                        Step.Child(fixedID: "0c8eb697-8aa6-4eed-a291-69ed3aa85237")
                    ],
                    actions: ["149f335f-15f6-4d8a-9e38-29a4ca435fd2" : actions]
                )
            ],
            redirectURL: nil,
            nextContentID: nil,
            renderContext: .modal)
    }
}

extension Experience.Step {
    init(fixedID: String, children: [Child], actions: [String: [Experience.Action]] = [:]) {
        self = .group(Group(
            id: UUID(uuidString: fixedID) ?? UUID(),
            type: "group",
            children: children,
            traits: [],
            actions: actions
        ))
    }
}

extension Experience.Step.Child {
    init(fixedID: String) {
        self.init(
            id: UUID(uuidString: fixedID) ?? UUID(),
            type: "modal",
            traits: [],
            actions: [:],
            content: ExperienceComponent.spacer(ExperienceComponent.SpacerModel(id: UUID(), spacing: nil, style: nil))
        )
    }

    init(formWithFixedID fixedID: String, defaultValue: String?, attributeName: String?) {
        self.init(
            id: UUID(uuidString: fixedID) ?? UUID(),
            type: "modal",
            traits: [],
            actions: [:],
            content: ExperienceComponent.textInput(ExperienceComponent.TextInputModel(
                id: UUID(uuidString: "f002dc4f-c5fc-4439-8916-0047a5839741")!,
                label: ExperienceComponent.TextModel(id: UUID(), text: "Form label - mock", style: nil),
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
                style: nil))
        )
    }

}

@available(iOS 13.0, *)
extension ExperienceData {
    static var mock: ExperienceData { ExperienceData(.mock, trigger: .showCall) }
    static var singleStepMock: ExperienceData { ExperienceData(.singleStepMock, trigger: .showCall) }
    static func mockWithForm(defaultValue: String?, attributeName: String? = nil, published: Bool = true) -> ExperienceData {
        ExperienceData(.mockWithForm(defaultValue: defaultValue, attributeName: attributeName ), trigger: .showCall, published: published)
    }
    static func mockWithStepActions(actions: [Experience.Action], trigger: ExperienceTrigger) -> ExperienceData {
        ExperienceData(.mockWithStepActions(actions: actions), trigger: trigger)
    }

    func package(presentExpectation: XCTestExpectation? = nil, dismissExpectation: XCTestExpectation? = nil) -> ExperiencePackage {
        package(onPresent: { presentExpectation?.fulfill() }, onDismiss: { dismissExpectation?.fulfill()} )
    }

    func package(
        onPresent: @escaping (() throws -> Void),
        onDismiss: @escaping (() -> Void),
        stepDecorator: ((Int, Int?) throws -> Void)? = nil
    ) -> ExperiencePackage {
        let pageMonitor = AppcuesExperiencePageMonitor(numberOfPages: 1, currentPage: 0)
        let containerController = Mocks.ContainerViewController(stepControllers: [UIViewController()], pageMonitor: pageMonitor)
        return ExperiencePackage(
            traitInstances: [],
            stepDecoratingTraitUpdater: { new, prev in try stepDecorator?(new, prev) },
            steps: self.steps[0].items,
            containerController: containerController,
            wrapperController: containerController,
            pageMonitor: pageMonitor,
            presenter: {
                containerController.mockIsBeingPresented = true
                containerController.eventHandler?.containerWillAppear()
                containerController.eventHandler?.containerDidAppear()
                containerController.mockIsBeingPresented = false
                try onPresent()
                $0?()
            },
            dismisser: {
                containerController.mockIsBeingDismissed = true
                containerController.eventHandler?.containerWillDisappear()
                containerController.eventHandler?.containerDidDisappear()
                containerController.mockIsBeingDismissed = false
                onDismiss()
                $0?()
            })
    }
}
