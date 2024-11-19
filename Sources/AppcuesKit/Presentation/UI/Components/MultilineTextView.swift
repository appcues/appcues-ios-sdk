//
//  MultilineTextView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-09-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

// defines the model properties that must be provided to style text input
// in the MultilineTextView implementation below
internal protocol TextInputStyling {
    var numberOfLines: Int? { get }
    var maxLength: Int? { get }
    var font: UIFont? { get }
    var textColor: UIColor? { get }
    var tintColor: UIColor? { get }
    var keyboardType: UIKeyboardType? { get }
    var textContentType: UITextContentType? { get }
}

// A base implementation of the TextInputStyling Protocol that can be used
// for any consumers of the MultilineTextView other than the
// ExperienceComponent.TextInputModel, which adheres to TextInputStyling directly
// in an extension below.
internal struct TextInputStyle: TextInputStyling {
    let numberOfLines: Int?
    let maxLength: Int?
    let font: UIFont?
    let textColor: UIColor?
    let tintColor: UIColor?
    let keyboardType: UIKeyboardType?
    let textContentType: UITextContentType?

    init(
        numberOfLines: Int? = nil,
        maxLength: Int? = nil,
        font: UIFont? = nil,
        textColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        keyboardType: UIKeyboardType? = nil,
        textContentType: UITextContentType? = nil
    ) {
        self.numberOfLines = numberOfLines
        self.maxLength = maxLength
        self.font = font
        self.textColor = textColor
        self.tintColor = tintColor
        self.keyboardType = keyboardType
        self.textContentType = textContentType
    }
}

// An implementation of text input for SwiftUI that provides full flexibility
// from iOS 13 and up, since SwiftUI TextField has different feature support
// on later iOS versions, and not all available in 13. This implementation
// wraps UIKit UITextField for single line, and UIKit UITextView for multi-line.
internal struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
    let model: TextInputStyling

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

        textView.font = model.font
        textView.textColor = model.textColor

        textView.tintColor = model.tintColor
        if let keyboardType = model.keyboardType {
            textView.keyboardType = keyboardType
        }
        textView.textContentType = model.textContentType

        textView.inputAccessoryView = DismissToolbar(textView: textView)

        return textView
    }

    private func makeTextField(context: Context) -> UITextField {
        let textField = PaddedTextField(insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        textField.backgroundColor = .clear

        textField.font = model.font
        textField.textColor = model.textColor

        textField.tintColor = model.tintColor
        if let keyboardType = model.keyboardType {
            textField.keyboardType = keyboardType
        }
        textField.textContentType = model.textContentType
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textField.inputAccessoryView = DismissToolbar(textField: textField)

        return textField
    }
}

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

    /// A `UIToolbar` that include a "Done" button to end editing. Use as an `inputAccessoryView`.
    ///
    /// This exists over just creating a `UIToolbar` because `MultilineTextView` is a struct
    /// and so can't have an `@objc` method for the selector.
    class DismissToolbar: UIToolbar {
        weak var view: UIView?

        init(textView: UITextView) {
            self.view = textView
            super.init(frame: .zero)
            setup()
        }

        init(textField: UITextField) {
            self.view = textField
            super.init(frame: .zero)
            setup()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setup() {
            items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
            ]
            sizeToFit()
        }

        @objc
        private func dismissKeyboard() {
            view?.endEditing(true)
        }
    }
}

extension ExperienceComponent.TextInputModel: TextInputStyling {
    var font: UIFont? {
        let fontSize = textFieldStyle?.fontSize ?? UIFont.labelFontSize
        return UIFont.matching(name: textFieldStyle?.fontName, size: fontSize)
    }

    var textColor: UIColor? {
        return UIColor(dynamicColor: textFieldStyle?.foregroundColor)
    }

    var tintColor: UIColor? {
        return UIColor(dynamicColor: cursorColor)
    }

    var keyboardType: UIKeyboardType? {
        return dataType?.keyboardType
    }

    var textContentType: UITextContentType? {
        return dataType?.textContentType
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
        case .url:
            return .URL
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
        case .url:
            return .URL
        }
    }
}
