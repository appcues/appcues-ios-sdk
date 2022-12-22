//
//  LanguageTranslator.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/21/22.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation
import MLKitTranslate

// reference
// concepts for using xcframwork with swift package https://github.com/nilsnilsnils/MLKitFrameworkTools
// additional https://github.com/d-date/google-mlkit-swiftpm

internal class LanguageTranslator {

    internal enum TranslationError: Error {
        case noTargetLanguage
        case translatorNotInitialized
        case noTranslation
    }

    private var translator: Translator?

    func initialize(sourceLanguageCode: String, targetLanguageCode: String?, completion: @escaping (Result<Translator, Error>) -> Void) {

        guard let targetLanguageCode = targetLanguageCode ?? Locale.current.languageCode else {
            completion(.failure(TranslationError.noTargetLanguage))
            return
        }

        let sourceLanguage = TranslateLanguage(rawValue: sourceLanguageCode)
        let targetLanguage = TranslateLanguage(rawValue: targetLanguageCode)

        let options = TranslatorOptions(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        let translator = Translator.translator(options: options)

        let conditions = ModelDownloadConditions(
            allowsCellularAccess: false,
            allowsBackgroundDownloading: true
        )

        translator.downloadModelIfNeeded(with: conditions) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self.translator = translator
            completion(.success(translator))
        }
    }

    func translate(_ experience: Experience, completion: @escaping (Experience) -> Void) {
        translate(experience.steps) { translated in
            completion(Experience(id: experience.id,
                                  name: experience.name,
                                  type: experience.type,
                                  publishedAt: experience.publishedAt,
                                  traits: experience.traits,
                                  steps: translated,
                                  redirectURL: experience.redirectURL,
                                  nextContentID: experience.nextContentID))
        }
    }

    private func translate(text: String, completion: @escaping (Result<String, Error>) -> Void) {

        guard let translator = translator else {
            completion(.failure(TranslationError.translatorNotInitialized))
            return
        }

        translator.translate(text) { translatedText, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let translatedText = translatedText else {
                completion(.failure(TranslationError.noTranslation))
                return
            }

            completion(.success(translatedText))
        }
    }

    private func translate(_ steps: [Experience.Step], completion: @escaping ([Experience.Step]) -> Void) {
        if steps.isEmpty {
            completion([])
            return
        }

        var steps = steps
        let next = steps.removeFirst()

        translate(next) { translated in
            self.translate(steps) { translatedRemainder in
                completion([translated] + translatedRemainder)
            }
        }
    }

    private func translate(_ children: [Experience.Step.Child], completion: @escaping ([Experience.Step.Child]) -> Void) {
        if children.isEmpty {
            completion([])
            return
        }

        var children = children
        let next = children.removeFirst()

        translate(next) { translated in
            self.translate(children) { translatedRemainder in
                completion([translated] + translatedRemainder)
            }
        }
    }

    private func translate(_ step: Experience.Step, completion: @escaping (Experience.Step) -> Void) {
        switch step {
        case let .group(group):
            translate(group.children) { translated in
                completion(Experience.Step.group(Experience.Step.Group(id: group.id,
                                                        type: group.type,
                                                        children: translated,
                                                        traits: group.traits,
                                                        actions: group.actions)))
            }

        case let .child(child):
            translate(child) { translated in
                completion(Experience.Step.child(translated))
            }
        }
    }

    private func translate(_ child: Experience.Step.Child, completion: @escaping (Experience.Step.Child) -> Void) {
        translate(child.content) { translated in
            completion(Experience.Step.Child(id: child.id,
                                             type: child.type,
                                             content: translated,
                                             traits: child.traits,
                                             actions: child.actions))
        }
    }

    private func translate(_ components: [ExperienceComponent], completion: @escaping ([ExperienceComponent]) -> Void) {
        if components.isEmpty {
            completion([])
            return
        }

        var components = components
        let next = components.removeFirst()

        translate(next) { translated in
            self.translate(components) { translatedRemainder in
                completion([translated] + translatedRemainder)
            }
        }
    }

    private func translate(_ component: ExperienceComponent, completion: @escaping (ExperienceComponent) -> Void) {
        switch component {
        case .stack(let model):
            translate(model.items) { translated in
                completion(.stack(ExperienceComponent.StackModel(id: model.id,
                                                                 orientation: model.orientation,
                                                                 distribution: model.distribution,
                                                                 spacing: model.spacing,
                                                                 items: translated,
                                                                 style: model.style)))
            }
        case .box(let model):
            translate(model.items) { translated in
                completion(.box(ExperienceComponent.BoxModel(id: model.id, items: translated, style: model.style)))
            }
        case .text(let model):
            translate(text: model.text) { result in
                switch result {
                case let .success(translatedText):
                    completion(.text(ExperienceComponent.TextModel(id: model.id, text: translatedText, style: model.style)))
                case .failure:
                    completion(component)
                }
            }
        case .button(let model):
            translate(model.content) { translated in
                completion(.button(ExperienceComponent.ButtonModel(id: model.id, content: translated, style: model.style)))
            }
        case .optionSelect(let model):
            completion(.optionSelect(model))
        case .textInput(let model):
            completion(.textInput(model))
        case .spacer, .embed, .image:
            completion(component)
        }
    }
}
