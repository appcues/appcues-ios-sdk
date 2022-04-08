//
//  FleetingLogView.swift
//  AppcuesKit
//
//  Created by Matt on 2022-04-06.
//  Copyright © 2022 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class FleetingLogView: UIView {
    typealias Orientation = (x: XOrientation, y: YOrientation)

    enum XOrientation {
        case leading, trailing
    }

    enum YOrientation {
        case top, bottom
    }

    // Prevents messages from showing iff `true`.
    var isLocked = false

    var maxItems: Int = 5

    var orientation: Orientation = (.trailing, .bottom) {
        didSet { layoutOrientation(oldValue: oldValue) }
    }

    private var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    private lazy var topConstraint = stackView.topAnchor.constraint(equalTo: topAnchor)
    private lazy var bottomConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            // Additional constraints are set depending on orientation
        ])

        layoutOrientation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.mask?.frame = bounds
    }

    func addMessage(_ message: String, symbolName: String? = nil) {
        guard !isLocked else { return }

        var translationX = stackView.frame.width
        if orientation.x == .leading {
            translationX *= -1
        }

        let view = FleetingItemView(message: message, symbolName: symbolName)
        view.setOrientation(orientation)
        view.isHidden = true
        view.transform = CGAffineTransform(translationX: translationX, y: 0)

        switch orientation.y {
        case .top:
            stackView.addArrangedSubview(view)
        case .bottom:
            stackView.insertArrangedSubview(view, at: 0)
        }

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 6.0
        ) {
            view.isHidden = false
            view.transform = .identity
        }

        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
            self?.removeMessage(view: view)
        }
    }

    private func removeMessage(view: UIView) {
        var translationX = stackView.frame.width
        if orientation.x == .leading {
            translationX *= -1
        }

        UIView.animate(
            withDuration: 0.3,
            animations: {
                view.transform = CGAffineTransform(translationX: translationX, y: 0)
                view.isHidden = true
            }, completion: { _ in
                view.removeFromSuperview()
            })
    }

    func clear() {
        stackView.arrangedSubviews.forEach(removeMessage(view:))
    }

    private func layoutOrientation(oldValue: Orientation? = nil) {
        let maskLayer = CAGradientLayer()
        maskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]

        switch orientation.x {
        case .leading:
            stackView.alignment = .leading
        case .trailing:
            stackView.alignment = .trailing
        }

        switch orientation.y {
        case .top:
            maskLayer.startPoint = CGPoint(x: 1, y: 0)
            maskLayer.endPoint = CGPoint(x: 1, y: 1)
            topConstraint.isActive = false
            bottomConstraint.isActive = true
        case .bottom:
            maskLayer.startPoint = CGPoint(x: 1, y: 1)
            maskLayer.endPoint = CGPoint(x: 1, y: 0)
            topConstraint.isActive = true
            bottomConstraint.isActive = false
        }

        // Reverse the stack order if we're switching y-axis values
        switch (oldValue?.y, orientation.y) {
        case (.top, .bottom), (.bottom, .top):
            stackView.arrangedSubviews.reversed().forEach { stackView.addArrangedSubview($0) }
        default:
            break
        }

        layer.mask = maskLayer

        stackView.arrangedSubviews.forEach {
            ($0 as? FleetingItemView)?.setOrientation(orientation)
        }
    }
}
