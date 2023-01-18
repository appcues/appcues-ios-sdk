//
//  AppcuesTargetElementTrait.swift
//  AppcuesKit
//
//  Created by James Ellis on 1/17/23.
//  Copyright © 2023 Appcues. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
internal class AppcuesTargetElementTrait: BackdropDecoratingTrait {
    struct Config: Decodable {
        let selector: ElementSelector
    }

    private class FrameObserverView: UIView {
        private var oldBounds: CGRect = .zero
        var onChange: ((_ bounds: CGRect) -> Void)?

        override func layoutSubviews() {
            super.layoutSubviews()
            if oldBounds != bounds {
                onChange?(bounds)
            }
            oldBounds = bounds
        }
    }

    static let type: String = "@appcues/target-element"

    weak var metadataDelegate: TraitMetadataDelegate?

    private let config: Config

    private lazy var frameObserverView = FrameObserverView()

    required init?(configuration: ExperiencePluginConfiguration, level: ExperienceTraitLevel) {
        guard let config = configuration.decode(Config.self) else { return nil }
        self.config = config
    }

    func decorate(backdropView: UIView) throws {
        metadataDelegate?.set([ "targetRectangle": try calculateRect(bounds: backdropView.bounds) ])

        // Monitor the backdrop bounds to recalculate target-element position on changes.
        backdropView.insertSubview(frameObserverView, at: 0)
        frameObserverView.pin(to: backdropView)

        frameObserverView.onChange = { [weak self] bounds in
            // this observer will ignore selector errors and use last known position on failure
            if let targetRectangle = try? self?.calculateRect(bounds: bounds) {
                self?.metadataDelegate?.set([ "targetRectangle": targetRectangle ])
                // Force an update so that traits depending on this value will update.
                self?.metadataDelegate?.publish()
            }
        }
    }

    func undecorate(backdropView: UIView) throws {
        metadataDelegate?.unset(keys: [ "targetRectangle" ])

        frameObserverView.removeFromSuperview()
        frameObserverView.onChange = nil
    }

    private func calculateRect(bounds: CGRect) throws -> CGRect {
        guard let window = UIApplication.shared.windows.first(where: { !($0 is DebugUIWindow) }) else {
            throw TraitError(description: "No active window found")
        }

        let view = try window.viewMatchingSelector(config.selector)
        return view.convert(view.bounds, to: nil)
    }
}

private extension UIView {

    func viewMatchingSelector(_ target: ElementSelector) throws -> UIView {
        let views = viewsMatchingSelector(target)

        guard !views.isEmpty else {
            throw TraitError(description: "No view matching selector \(target)")
        }

        // if only a single match of anything, use it
        if views.count == 1 {
            return views[0]
        }

        // try to use single match on accessibilityIdentifier
        if let match = views.findSingleMatch(for: target, on: \.accessibilityIdentifier) {
            return match
        }

        // try to use single match on tag
        if let match = views.findSingleMatch(for: target, on: \.tag) {
            return match
        }

        // try to use single match on description
        if let match = views.findSingleMatch(for: target, on: \.description) {
            return match
        }

        throw TraitError(description: "multiple non-distinct views (\(views.count)) matched selector \(target)")
    }

    func viewsMatchingSelector(_ target: ElementSelector) -> [UIView] {
        var views: [UIView] = []

        if let current = self.appcuesSelector {
            if (target.accessibilityIdentifier != nil && target.accessibilityIdentifier == current.accessibilityIdentifier) ||
                (target.tag != nil && target.tag == current.tag) ||
                (target.description != nil && target.description == current.description) {
                views.append(self)
            }
        }

        for subview in self.subviews {
            views.append(contentsOf: subview.viewsMatchingSelector(target))
        }

        return views
    }
}

private extension Array where Element == UIView {
    // find a single item that matches the criteria, based on the accessor
    // i.e. a single item that matches the accessibilityIdentifier
    func findSingleMatch(for targetSelector: ElementSelector, on keyPath: KeyPath<ElementSelector, String?>) -> UIView? {
        let matches = self.filter {
            guard let selector = $0.appcuesSelector else { return false }
            return selector[keyPath: keyPath] == targetSelector[keyPath: keyPath]
        }
        if matches.count == 1 {
            return matches[0]
        }
        return nil
    }
}
