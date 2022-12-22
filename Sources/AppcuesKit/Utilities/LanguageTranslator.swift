//
//  LanguageTranslator.swift
//  AppcuesKit
//
//  Created by James Ellis on 12/21/22.
//  Copyright ’ 2022 Appcues. All rights reserved.
//

import Foundation
import MLKitTranslate

internal class LanguageTranslator {

    internal enum TranslationError: Error {
        case noTargetLanguage
        case translatorNotInitialized
        case noTranslation
    }

    private var translator: Translator?

    func initialize(sourceLanguageCode: String, targetLanguageCode: String?, completion: @escaping (Result<Translator, Error>) -> Void) {

        let preferedLanguageCodes = Locale.preferredLanguages
            .compactMap { Locale(identifier: $0) }
            .compactMap { $0.languageCode }

        guard let targetLanguageCode = targetLanguageCode ?? preferedLanguageCodes.first else {
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

    private func translate(_ textComponent: ExperienceComponent.TextModel?, completion: @escaping (ExperienceComponent.TextModel?) -> Void) {
        guard let textComponent = textComponent else {
            completion(nil)
            return
        }

        translate(textComponent, completion: completion)
    }

    private func translate(_ textComponent: ExperienceComponent.TextModel, completion: @escaping (ExperienceComponent.TextModel) -> Void) {
        translate(text: textComponent.text) { result in
            switch result {
            case let .success(translatedText):
                completion(ExperienceComponent.TextModel(id: textComponent.id, text: translatedText, style: textComponent.style))
            case .failure:
                completion(textComponent)
            }
        }
    }

    private func translate(_ options: [ExperienceComponent.FormOptionModel], completion: @escaping ([ExperienceComponent.FormOptionModel]) -> Void) {
        if options.isEmpty {
            completion([])
            return
        }

        var options = options
        let next = options.removeFirst()

        translate(next) { translated in
            self.translate(options) { translatedRemainder in
                completion([translated] + translatedRemainder)
            }
        }
    }

    private func translate(_ option: ExperienceComponent.FormOptionModel, completion: @escaping (ExperienceComponent.FormOptionModel) -> Void) {
        translate(option.content) { translatedContent in
            self.translate(option.selectedContent) { translatedSelectedContent in
                completion(ExperienceComponent.FormOptionModel(value: option.value, content: translatedContent, selectedContent: translatedSelectedContent))
            }
        }
    }

    private func translate(_ component: ExperienceComponent?, completion: @escaping (ExperienceComponent?) -> Void) {
        guard let component = component else {
            completion(nil)
            return
        }

        translate(component, completion: completion)
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
            translate(model) { translatedModel in
                completion(.text(translatedModel))
            }
        case .button(let model):
            translate(model.content) { translated in
                completion(.button(ExperienceComponent.ButtonModel(id: model.id, content: translated, style: model.style)))
            }
        case .optionSelect(let model):
            translate(model.label) { translatedLabel in
                self.translate(model.errorLabel) { translatedErrorLabel in
                    self.translate(model.options) { translatedOptions in
                        completion(.optionSelect(ExperienceComponent.OptionSelectModel(id: model.id,
                                                                                       label: translatedLabel,
                                                                                       errorLabel: translatedErrorLabel,
                                                                                       selectMode: model.selectMode,
                                                                                       options: translatedOptions,
                                                                                       defaultValue: model.defaultValue,
                                                                                       minSelections: model.minSelections,
                                                                                       maxSelections: model.maxSelections,
                                                                                       controlPosition: model.controlPosition,
                                                                                       displayFormat: model.displayFormat,
                                                                                       selectedColor: model.selectedColor,
                                                                                       unselectedColor: model.unselectedColor,
                                                                                       accentColor: model.accentColor,
                                                                                       pickerStyle: model.pickerStyle,
                                                                                       attributeName: model.attributeName,
                                                                                       leadingFill: model.leadingFill,
                                                                                       style: model.style)))
                    }
                }
            }
        case .textInput(let model):
            translate(model.label) { translatedLabel in
                self.translate(model.errorLabel) { translatedErrorLabel in
                    self.translate(model.placeholder) { translatedPlaceholder in
                        completion(.textInput(ExperienceComponent.TextInputModel(id: model.id,
                                                                                 label: translatedLabel,
                                                                                 errorLabel: translatedErrorLabel,
                                                                                 placeholder: translatedPlaceholder,
                                                                                 defaultValue: model.defaultValue,
                                                                                 required: model.required,
                                                                                 numberOfLines: model.numberOfLines,
                                                                                 maxLength: model.maxLength,
                                                                                 dataType: model.dataType,
                                                                                 textFieldStyle: model.textFieldStyle,
                                                                                 cursorColor: model.cursorColor,
                                                                                 attributeName: model.attributeName,
                                                                                 style: model.style)))
                    }
                }
            }
        case .spacer, .embed, .image:
            completion(component)
        }
    }
}
