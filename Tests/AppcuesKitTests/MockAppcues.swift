//
//  MockAppcues.swift
//  AppcuesKitTests
//
//  Created by James Ellis on 1/7/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
import UserNotifications
@testable import AppcuesKit

enum MockError: Error {
    case noMock
    case invalidSuccessType
}

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
        container.register(PushMonitoring.self, value: pushMonitor)

        container.register(DeepLinkHandling.self, value: deepLinkHandler)
        container.register(UIDebugging.self, value: debugger)
        container.register(ContentLoading.self, value: contentLoader)
        container.register(ExperienceRendering.self, value: experienceRenderer)
        container.register(TraitComposing.self, value: traitComposer)
        container.registerLazy(TraitRegistry.self, initializer: TraitRegistry.init)
        container.registerLazy(ActionRegistry.self, initializer: ActionRegistry.init)

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
    var contentLoader = MockContentLoader()
    var sessionMonitor = MockSessionMonitor()
    var activityProcessor = MockActivityProcessor()
    var debugger = MockDebugger()
    var deepLinkHandler = MockDeepLinkHandler()
    var activityStorage = MockActivityStorage()
    var networking = MockNetworking()
    var analyticsTracker = MockAnalyticsTracker()
    var pushMonitor = MockPushMonitor()
    var experienceRenderer = MockExperienceRenderer()
    var traitComposer = MockTraitComposer()
}

class MockAnalyticsPublisher: AnalyticsPublishing {

    var onPublish: ((TrackingUpdate) -> Void)?
    func publish(_ update: TrackingUpdate) {
        onPublish?(update)
    }

    var onLog: ((TrackingUpdate) -> Void)?
    func log(_ update: TrackingUpdate) {
        onLog?(update)
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
    var pushToken: String?
}

class MockContentLoader: ContentLoading {

    var onLoad: ((String, Bool, ExperienceTrigger) throws -> Void)?
    func load(experienceID: String, published: Bool, queryItems: [URLQueryItem], trigger: ExperienceTrigger) async throws {
        try onLoad?(experienceID, published, trigger)
    }

    var onLoadPush: ((String, Bool, [URLQueryItem]) throws -> Void)?
    func loadPush(id: String, published: Bool, queryItems: [URLQueryItem]) async throws {
        try onLoadPush?(id, published, queryItems)
    }
}

class MockExperienceRenderer: ExperienceRendering {
    var onStart: ((StateMachineOwning, RenderContext) -> Void)?
    func start(owner: StateMachineOwning, forContext context: RenderContext) {
        onStart?(owner, context)
    }
    
    var onProcessAndShow: (([ExperienceData], ExperienceTrigger) -> Void)?
    func processAndShow(qualifiedExperiences: [ExperienceData], reason: ExperienceTrigger) {
        onProcessAndShow?(qualifiedExperiences, reason)
    }
    
    var onProcessAndShowExperience: ((ExperienceData) throws -> Void)?
    func processAndShow(experience: AppcuesKit.ExperienceData) async throws {
        try onProcessAndShowExperience?(experience)
    }
    
    var onShowStep: ((StepReference, RenderContext) throws -> Void)?
    func show(step stepRef: StepReference, inContext context: RenderContext) async throws {
        try onShowStep?(stepRef, context)
    }
    
    var onDismiss: ((RenderContext, Bool) throws -> Void)?
    func dismiss(inContext context: AppcuesKit.RenderContext, markComplete: Bool) async throws {
        try onDismiss?(context, markComplete)
    }

    var onExperienceData: ((RenderContext) -> ExperienceData?)?
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

    var onResetAll: (() -> Void)?
    func resetAll() {
        onResetAll?()
    }
}

class MockSessionMonitor: SessionMonitoring {
    var isSessionExpired: Bool = false

    var onStart: (() -> Bool)?
    func start() -> Bool {
        return onStart?() ?? true
    }

    var onReset: (() -> Void)?
    func reset() {
        onReset?()
    }

    var onUpdateLastActivity: (() -> Void)?
    func updateLastActivity() {
        onUpdateLastActivity?()
    }

}

class MockActivityProcessor: ActivityProcessing {

    var onProcess: ((Activity) throws -> QualifyResponse)?
    func process(_ activity: Activity) async throws -> QualifyResponse {
        guard let onProcess = onProcess else {
            throw MockError.noMock
        }
        return try onProcess(activity)
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

    var onShowToast: ((DebugToast) -> Void)?
    func showToast(_ toast: DebugToast) {
        onShowToast?(toast)
    }
}

class MockDeepLinkHandler: DeepLinkHandling {

    var onDidHandleURL: ((URL) -> Bool)?
    func didHandleURL(_ url: URL) -> Bool {
        return onDidHandleURL?(url) ?? false
    }
}

class MockTraitComposer: TraitComposing {

    @MainActor private var onPackage: ((ExperienceData, Experience.StepIndex) throws -> ExperiencePackage)?
    @MainActor func setPackage(_ onPackage: (@MainActor (ExperienceData, Experience.StepIndex) throws -> ExperiencePackage)?) {
        self.onPackage = onPackage
    }
    @MainActor func package(experience: ExperienceData, stepIndex: Experience.StepIndex) throws -> ExperiencePackage {
        guard let onPackage = onPackage else {
            throw MockError.noMock
        }

        return try onPackage(experience, stepIndex)
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
    var onGet: ((Endpoint, Authorization?) throws -> Any)?
    func get<T>(from endpoint: Endpoint, authorization: Authorization?) async throws -> T where T : Decodable {
        guard let onGet = onGet else {
            throw MockError.noMock
        }

        let value = try onGet(endpoint, authorization)
        if let converted = value as? T {
            return converted
        } else {
            throw MockError.invalidSuccessType
        }
    }

    var onPost: ((Endpoint, Authorization?, Data?, UUID?) throws -> Any)?
    func post<T>(to endpoint: Endpoint, authorization: Authorization?, body: Data?, requestId: UUID?) async throws -> T where T : Decodable {
        guard let onPost = onPost else {
            throw MockError.noMock
        }

        let value = try onPost(endpoint, authorization, body, requestId)
        if let converted = value as? T {
            return converted
        } else {
            throw MockError.invalidSuccessType
        }
    }

    var onPostEmptyResponse: ((Endpoint, Authorization?, Data?) throws -> Void)?
    func post(to endpoint: Endpoint, authorization: Authorization?, body: Data?) async throws {
        guard let onPostEmptyResponse = onPostEmptyResponse else {
            throw MockError.noMock
        }

        try onPostEmptyResponse(endpoint, authorization, body)
    }

    var onPutEmptyResponse: ((Endpoint, Authorization?, Data, String) throws -> Void)?
    func put(to endpoint: Endpoint, authorization: Authorization?, body: Data, contentType: String) async throws {
        guard let onPutEmptyResponse = onPutEmptyResponse else {
            throw MockError.noMock
        }

        try onPutEmptyResponse(endpoint, authorization, body, contentType)
    }
}

class MockAnalyticsTracker: AnalyticsTracking {
    var onFlush: (() -> Void)?
    func flush() {
        onFlush?()
    }
}

class MockPushMonitor: PushMonitoring {
    var pushEnvironment: AppcuesKit.PushEnvironment = .development
    var pushEnabled: Bool = false
    var pushBackgroundEnabled: Bool = false
    var pushPrimerEligible: Bool = false

    var pushAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    var onConfigureAutomatically: (() -> Void)?
    func configureAutomatically() {
        onConfigureAutomatically?()
    }

    var onSetPushToken: ((Data?) -> Void)?
    func setPushToken(_ deviceToken: Data?) {
        onSetPushToken?(deviceToken)
    }

    var onRefreshPushStatus: (() -> UNAuthorizationStatus)?
    func refreshPushStatus() async -> UNAuthorizationStatus {
        onRefreshPushStatus?() ?? .notDetermined
    }

    var onDidReceiveNotification: ((UNNotificationResponse) -> Bool)?
    func didReceiveNotification(response: UNNotificationResponse) -> Bool {
        onDidReceiveNotification?(response) ?? false
    }

    var onAttemptDeferredNotificationResponse: (() -> Void)?
    func attemptDeferredNotificationResponse() -> Bool {
        onAttemptDeferredNotificationResponse?()
        return false
    }

}
