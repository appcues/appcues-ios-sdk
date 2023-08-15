//
//  CaptureToastView.swift
//  AppcuesKit
//
//  Created by James Ellis on 3/8/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

internal class CaptureToastView: UIView {

    var onRetry: (() -> Void)?

    private var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .center
        view.spacing = 8.0
        view.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        view.isLayoutMarginsRelativeArrangement = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private var retryButton: UIButton = {
        let button = UIButton()
        button.setTitle("Try again", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 6.0
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 6.0

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(retryButton)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            retryButton.heightAnchor.constraint(equalToConstant: 40),
            retryButton.widthAnchor.constraint(equalToConstant: 90)
        ])

        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureAppearance(for toast: DebugToast) {
        switch toast.style {
        case .success:
            backgroundColor = .appcuesToastSuccess
        case .failure:
            backgroundColor = .appcuesToastFailure
        }
        retryButton.isHidden = toast.retryAction == nil
        onRetry = toast.retryAction

        messageLabel.attributedText = toast.message.attributedText
    }

    @objc
    func retryButtonTapped() {
        onRetry?()
    }
}

private extension UIColor {
    static let appcuesToastSuccess = UIColor(red: 0.0, green: 0.447, blue: 0.839, alpha: 1.0)
    static let appcuesToastFailure = UIColor(red: 0.867, green: 0.133, blue: 0.439, alpha: 1.0)
}

extension DebugToast.Message {
    var attributedText: NSAttributedString {
        switch self {
        case .screenCaptureSuccess(let displayName):
            let message = NSMutableAttributedString(string: "\"\(displayName)\"", attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white
            ])
            message.append(NSAttributedString(string: " is now available for preview and targeting.", attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.white
            ]))
            return message
        case .screenCaptureFailure:
            return NSAttributedString(string: "Screen capture failed", attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white
            ])
        case .screenUploadFailure:
            return NSAttributedString(string: "Upload failed", attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white
            ])
        case .custom(let text):
            return NSAttributedString(string: text, attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white
            ])
        }
    }
}
