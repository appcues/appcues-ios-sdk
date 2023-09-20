//
//  FleetingItemView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class FleetingItemView: UIView {
    private var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 4
        stack.layoutMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    private var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .caption1, scale: .small)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        return imageView
    }()

    init(message: String, symbolName: String?) {
        super.init(frame: .zero)

        messageLabel.text = message
        if let symbolName = symbolName {
            iconImageView.image = UIImage(systemName: symbolName)
        }

        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(messageLabel)

        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)

        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)

        vibrancyEffectView.contentView.addSubview(stackView)
        blurredEffectView.contentView.addSubview(vibrancyEffectView)
        addSubview(blurredEffectView)

        addSubview(blurredEffectView)

        stackView.pin(to: vibrancyEffectView.contentView)
        vibrancyEffectView.pin(to: blurredEffectView.contentView)
        blurredEffectView.pin(to: self)

        layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.height / 2
    }

    func setOrientation(_ orientation: FleetingLogView.Orientation) {
        switch orientation.x {
        case .left:
            messageLabel.textAlignment = .left
            stackView.semanticContentAttribute = .forceLeftToRight
        case .right:
            messageLabel.textAlignment = .right
            stackView.semanticContentAttribute = .forceRightToLeft
        }
    }
}
