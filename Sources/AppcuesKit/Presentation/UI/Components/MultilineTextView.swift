//
//  MultilineTextView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-09-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
    let model: ExperienceComponent.TextInputModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        if (model.numberOfLines ?? 1) > 1 {
            return makeTextView(context: context)
        } else {
            return makeTextField(context: context)
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let textView = uiView as? UITextView {
            textView.text = text
        } else if let textField = uiView as? UITextField {
            textField.text = text
        }
    }

    private func makeTextView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let fontSize = model.textFieldStyle?.fontSize ?? UIFont.labelFontSize
        textView.font = UIFont.matching(name: model.textFieldStyle?.fontName, size: fontSize)
        textView.textColor = UIColor(dynamicColor: model.textFieldStyle?.foregroundColor)

        textView.tintColor = UIColor(dynamicColor: model.cursorColor)
        if let keyboardType = model.dataType?.keyboardType {
            textView.keyboardType = keyboardType
        }
        textView.textContentType = model.dataType?.textContentType

        return textView
    }

    private func makeTextField(context: Context) -> UITextField {
        let textField = PaddedTextField(insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        textField.backgroundColor = .clear

        let fontSize = model.textFieldStyle?.fontSize ?? UIFont.labelFontSize
        textField.font = UIFont.matching(name: model.textFieldStyle?.fontName, size: fontSize)
        textField.textColor = UIColor(dynamicColor: model.textFieldStyle?.foregroundColor)

        textField.tintColor = UIColor(dynamicColor: model.cursorColor)
        if let keyboardType = model.dataType?.keyboardType {
            textField.keyboardType = keyboardType
        }
        textField.textContentType = model.dataType?.textContentType
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return textField
    }
}

@available(iOS 13.0, *)
extension MultilineTextView {
    class Coordinator: NSObject, UITextViewDelegate, UITextFieldDelegate {
        var parent: MultilineTextView

        init(_ multilineTextView: MultilineTextView) {
            self.parent = multilineTextView
        }

        // MARK: UITextViewDelegate

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let maxLength = parent.model.maxLength else { return true }

            let currentText = textView.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
            return updatedText.count <= maxLength
        }

        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
        }

        // MARK: UITextFieldDelegate

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let maxLength = parent.model.maxLength else { return true }

            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            return updatedText.count <= maxLength
        }

        @objc
        func textFieldDidChange(_ textField: UITextField) {
            self.parent.text = textField.text ?? ""
        }
    }

    class PaddedTextField: UITextField {
        let insets: UIEdgeInsets

        init(insets: UIEdgeInsets) {
            self.insets = insets
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func textRect(forBounds bounds: CGRect) -> CGRect {
            return bounds.inset(by: insets)
        }

        override func editingRect(forBounds bounds: CGRect) -> CGRect {
            return self.textRect(forBounds: bounds)
        }
    }
}

extension ExperienceComponent.TextInputModel.DataType {
    var keyboardType: UIKeyboardType? {
        switch self {
        case .text, .name, .address:
            return nil
        case .number:
            return .numberPad
        case .email:
            return .emailAddress
        case .phone:
            return .phonePad
        }
    }

    var textContentType: UITextContentType? {
        switch self {
        case .text, .number:
            return nil
        case .email:
            return .emailAddress
        case .phone:
            return .telephoneNumber
        case .name:
            return .name
        case .address:
            return .fullStreetAddress
        }
    }
}
