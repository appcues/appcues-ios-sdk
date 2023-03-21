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
        let contentPreferredPosition: ContentPosition?
        let contentDistanceFromTarget: Double?
        let selector: [String: String]
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
        // Determine if the selector can be resolved to a view, failing the step if not.
        let targetRect = try calculateRect()
        // The first decorate call on the first step in a group will have a nil window because the views aren't added yet,
        // so skip setting a targetRectangle until we have proper bounds. The change handler below will take care of that.
        if backdropView.window != nil {
            metadataDelegate?.set([
                "contentPreferredPosition": config.contentPreferredPosition,
                "contentDistanceFromTarget": CGFloat(config.contentDistanceFromTarget ?? 0),
                "targetRectangle": targetRect
            ])
        }

        // Monitor the backdrop bounds to recalculate target-element position on changes.
        backdropView.insertSubview(frameObserverView, at: 0)
        frameObserverView.pin(to: backdropView)
        // Ensure the view bounds are updated *before* we add the frame observer block.
        frameObserverView.layoutIfNeeded()

        frameObserverView.onChange = { [weak self] _ in
            // this observer will ignore selector errors and use last known position on failure
            if let targetRectangle = try? self?.calculateRect() {
                self?.metadataDelegate?.set([
                    "contentPreferredPosition": self?.config.contentPreferredPosition,
                    "contentDistanceFromTarget": CGFloat(self?.config.contentDistanceFromTarget ?? 0),
                    "targetRectangle": targetRectangle
                ])
                // Force an update so that traits depending on this value will update.
                self?.metadataDelegate?.publish()
            }
        }
    }

    func undecorate(backdropView: UIView) throws {
        metadataDelegate?.unset(keys: [ "contentPreferredPosition", "contentDistanceFromTarget", "targetRectangle" ])

        frameObserverView.removeFromSuperview()
        frameObserverView.onChange = nil
    }

    private func calculateRect() throws -> CGRect {
        let view = try viewMatchingSelector()
        return CGRect(x: view.x, y: view.y, width: view.width, height: view.height)
    }

    private func viewMatchingSelector() throws -> AppcuesViewElement {

        let strategy = Appcues.elementTargeting

        guard let selector = strategy.inflateSelector(from: config.selector) else {
            throw TraitError(description: "Invalid selector \(config.selector)")
        }

        let views = strategy.findMatches(for: selector)

        guard !views.isEmpty else {
            throw TraitError(description: "No view matching selector \(config.selector)")
        }

        // if only a single match of anything, use it
        if views.count == 1 {
            return views[0]
        }

        // weight the selector property matches by how distinct they are considered
        let weightedMatches = views.map { view -> (AppcuesViewElement, Int) in
            let weight = view.selector?.evaluateMatch(for: selector) ?? 0
            return (view, weight)
        }

        // find the maximum weight value from all matches
        if let maxWeight = weightedMatches.max(by: { $0.1 > $1.1 })?.1 {
            // find the items with this weight
            let maxItems = weightedMatches.filter { $0.1 == maxWeight }
            // if this has produced a single most distinct result, use it
            if maxItems.count == 1 {
                return maxItems[0].0
            }
        }

        // otherwise, this selector was not able to find a distinct match in this view
        throw TraitError(description: "multiple non-distinct views (\(views.count)) matched selector \(config.selector)")
    }
}
