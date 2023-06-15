//
//  MockAppcues.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 1/7/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
@testable import AppcuesKit

class MockAppcues: Appcues {
    init() {
        super.init(config: Appcues.Config(accountID: "00000", applicationID: "abc"))
    }

    override init(config: Config) {
        super.init(config: config)
    }

    override func initializeContainer() {
        container.owner = self
        container.register(Appcues.Config.self, value: config)
        container.register(AnalyticsPublishing.self, value: analyticsPublisher)
        container.register(DataStoring.self, value: storage)
        container.register(Networking.self, value: networking)
        container.register(SessionMonitoring.self, value: sessionMonitor)
        container.register(ActivityProcessing.self, value: activityProcessor)
        container.register(ActivityStoring.self, value: activityStorage)
        container.register(AnalyticsTracking.self, value: analyticsTracker)

        if #available(iOS 13.0, *) {
            container.register(DeepLinkHandling.self, value: deepLinkHandler)
            container.register(UIDebugging.self, value: debugger)
            container.register(ExperienceLoading.self, value: experienceLoader)
            container.register(ExperienceRendering.self, value: MockExperienceRenderer())
            container.registerLazy(TraitRegistry.self, initializer: TraitRegistry.init)
            container.registerLazy(ActionRegistry.self, initializer: ActionRegistry.init)
            container.register(TraitComposing.self, value: MockTraitComposer())
        }

        // dependencies that are not mocked
        container.registerLazy(NotificationCenter.self, initializer: NotificationCenter.init)
        container.registerLazy(UIKitScreenTracker.self, initializer: UIKitScreenTracker.init)
        container.registerLazy(AnalyticsBroadcaster.self, initializer: AnalyticsBroadcaster.init)

    }

    var onIdentify: ((String, [String: Any]?) -> Void)?
    override func identify(userID: String, properties: [String : Any]? = nil) {
        onIdentify?(userID, properties)
        super.identify(userID: userID, properties: properties)
    }

    var analyticsPublisher = MockAnalyticsPublisher()
    var storage = MockStorage()
    var experienceLoader = MockExperienceLoader()
    var sessionMonitor = MockSessionMonitor()
    var activityProcessor = MockActivityProcessor()
    var debugger = MockDebugger()
    var deepLinkHandler = MockDeepLinkHandler()
    var activityStorage = MockActivityStorage()
    var networking = MockNetworking()
    var analyticsTracker = MockAnalyticsTracker()

    // must wrap in @available since MockExperienceRenderer has a stored property with
    // type ExperienceData in it, which is 13+
    @available(iOS 13.0, *)
    var experienceRenderer: MockExperienceRenderer {
        return container.resolve(ExperienceRendering.self) as! MockExperienceRenderer
    }

    // must wrap in @available since MockTraitComposer has a stored property with
    // type ExperienceData in it, which is 13+
    @available(iOS 13.0, *)
    var traitComposer: MockTraitComposer {
        return container.resolve(TraitComposing.self) as! MockTraitComposer
    }
}

class MockAnalyticsPublisher: AnalyticsPublishing {

    var onPublish: ((TrackingUpdate) -> Void)?
    func publish(_ update: TrackingUpdate) {
        onPublish?(update)
    }

    var onRegisterSubscriber: ((AnalyticsSubscribing) -> Void)?
    func register(subscriber: AnalyticsSubscribing) {
        onRegisterSubscriber?(subscriber)
    }

    var onRemoveSubscriber: ((AnalyticsSubscribing) -> Void)?
    func remove(subscriber: AnalyticsSubscribing) {
        onRemoveSubscriber?(subscriber)
    }

    var onRegisterDecorator: ((AnalyticsDecorating) -> Void)?
    func register(decorator: AnalyticsDecorating) {
        onRegisterDecorator?(decorator)
    }

    var onRemoveDecorator: ((AnalyticsDecorating) -> Void)?
    func remove(decorator: AnalyticsDecorating) {
        onRemoveDecorator?(decorator)
    }
}

class MockStorage: DataStoring {
    var deviceID: String = "device-id"
    var userID: String = "user-id"
    var groupID: String?
    var isAnonymous: Bool = false
    var lastContentShownAt: Date?
    var userSignature: String?
}

class MockExperienceLoader: ExperienceLoading {

    var onLoad: ((String, Bool, ExperienceTrigger, ((Result<Void, Error>) -> Void)?) -> Void)?
    func load(experienceID: String, published: Bool, trigger: ExperienceTrigger, completion: ((Result<Void, Error>) -> Void)?) {
        onLoad?(experienceID, published, trigger, completion)
    }
}

@available(iOS 13.0, *) // due to reference to ExperienceData
class MockExperienceRenderer: ExperienceRendering {
    var onStart: ((StateMachineOwning, RenderContext) -> Void)?
    func start(owner: StateMachineOwning, forContext context: RenderContext) {
        onStart?(owner, context)
    }

    var onProcessAndShow: (([ExperienceData]) -> Void)?
    func processAndShow(qualifiedExperiences: [ExperienceData]) {
        onProcessAndShow?(qualifiedExperiences)
    }

    var onShowExperience: ((ExperienceData, ((Result<Void, Error>) -> Void)?) -> Void)?
    func show(experience: ExperienceData, completion: ((Result<Void, Error>) -> Void)?) {
        onShowExperience?(experience, completion)
    }

    var onShowStep: ((StepReference, RenderContext, (() -> Void)?) -> Void)?
    func show(step stepRef: StepReference, inContext context: RenderContext, completion: (() -> Void)?) {
        onShowStep?(stepRef, context, completion)
    }

    var onDismiss: ((RenderContext, Bool, ((Result<Void, Error>) -> Void)?) -> Void)?
    func dismiss(inContext context: RenderContext, markComplete: Bool, completion: ((Result<Void, Error>) -> Void)?) {
        onDismiss?(context, markComplete, completion)
    }

    var onExperienceData: ((RenderContext) -> ExperienceData)?
    func experienceData(forContext context: RenderContext) -> ExperienceData? {
        onExperienceData?(context)
    }

    var onStepIndex: ((RenderContext) -> Experience.StepIndex)?
    func stepIndex(forContext context: RenderContext) -> Experience.StepIndex? {
        onStepIndex?(context)
    }

    var onOwner: ((RenderContext) -> StateMachineOwning)?
    func owner(forContext context: RenderContext) -> StateMachineOwning? {
        onOwner?(context)
    }

}

class MockSessionMonitor: SessionMonitoring {
    var onStart: (() -> Void)?
    var onReset: (() -> Void)?

    func start() {
        onStart?()
    }

    func reset() {
        onReset?()
    }
}

class MockActivityProcessor: ActivityProcessing {

    var onProcess: ((Activity, (Result<QualifyResponse, Error>) -> Void) -> Void)?

    func process(_ activity: Activity, completion: @escaping (Result<QualifyResponse, Error>) -> Void) {
        onProcess?(activity, completion)
    }
}

class MockDebugger: UIDebugging {

    var onVerify: ((String) -> Void)?
    func verifyInstall(token: String) {
        onVerify?(token)
    }

    var onShow: ((DebugMode) -> Void)?
    func show(mode: DebugMode) {
        onShow?(mode)
    }
}

class MockDeepLinkHandler: DeepLinkHandling {

    var onDidHandleURL: ((URL) -> Bool)?
    func didHandleURL(_ url: URL) -> Bool {
        return onDidHandleURL?(url) ?? false
    }
}

@available(iOS 13.0, *) // due to reference to ExperienceData
class MockTraitComposer: TraitComposing {

    var onPackage: ((ExperienceData, Experience.StepIndex) throws -> ExperiencePackage)?
    func package(experience: ExperienceData, stepIndex: Experience.StepIndex) throws -> ExperiencePackage {
        if let onPackage = onPackage {
            return try onPackage(experience, stepIndex)
        } else {
            throw AppcuesTraitError(description: "no mock set")
        }
    }
}

class MockActivityStorage: ActivityStoring {

    var onSave: ((ActivityStorage) -> Void)?
    func save(_ activity: ActivityStorage) {
        onSave?(activity)
    }

    var onRemove: ((ActivityStorage) -> Void)?
    func remove(_ activity: ActivityStorage) {
        onRemove?(activity)
    }

    var onRead: (() -> [ActivityStorage])?
    func read() -> [ActivityStorage] {
        return onRead?() ?? []
    }
}

class MockNetworking: Networking {

    enum MockError: Error {
        case noMock
        case invalidSuccessType
    }

    var onGet: ((Endpoint, Authorization?) -> Result<Any, Error>)?
    func get<T>(from endpoint: Endpoint,
                authorization: Authorization?,
                completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        guard let result = onGet?(endpoint, authorization) else {
            completion(.failure(MockError.noMock))
            return
        }
        switch result {
        case .success(let value):
            if let converted = value as? T {
                completion(.success(converted))
            }
            else {
                completion(.failure(MockError.invalidSuccessType))
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }

    var onPost: ((Endpoint, Authorization?, Data?, UUID?, ((Result<Any, Error>) -> Void)) -> Void)?
    func post<T>(to endpoint: Endpoint,
                 authorization: Authorization?,
                 body: Data?,
                 requestId: UUID?,
                 completion: @escaping (Result<T, Error>) -> Void) where T : Decodable {
        guard let onPost = onPost else {
            completion(.failure(MockError.noMock))
            return
        }
        onPost(endpoint, authorization, body, requestId) { result in
            switch result {
            case .success(let value):
                if let converted = value as? T {
                    completion(.success(converted))
                }
                else {
                    completion(.failure(MockError.invalidSuccessType))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    var onPostEmptyResponse: ((Endpoint, Authorization?, Data?, ((Result<Void, Error>) -> Void)) -> Void)?
    func post(to endpoint: Endpoint,
              authorization: Authorization?,
              body: Data?,
              completion: @escaping (Result<Void, Error>) -> Void) {

        guard let onPostEmptyResponse = onPostEmptyResponse else {
            completion(.failure(MockError.noMock))
            return
        }

        onPostEmptyResponse(endpoint, authorization, body, completion)
    }

    var onPutEmptyResponse: ((Endpoint, Authorization?, Data, String, ((Result<Void, Error>) -> Void)) -> Void)?
    func put(to endpoint: Endpoint,
             authorization: Authorization?,
             body: Data,
             contentType: String,
             completion: @escaping (Result<Void, Error>) -> Void) {

        guard let onPutEmptyResponse = onPutEmptyResponse else {
            completion(.failure(MockError.noMock))
            return
        }

        onPutEmptyResponse(endpoint, authorization, body, contentType, completion)
    }
}

class MockAnalyticsTracker: AnalyticsTracking {
    var onFlush: (() -> Void)?
    func flush() {
        onFlush?()
    }
}
