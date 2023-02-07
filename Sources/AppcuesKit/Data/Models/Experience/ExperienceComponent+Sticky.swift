//
//  ExperienceComponent+Sticky.swift
//  AppcuesKit
//
//  Created by Matt on 2023-02-07.
//  Copyright © 2023 Appcues. All rights reserved.
//

import Foundation

// swiftlint:disable large_tuple

extension ExperienceComponent {
    /// Extract sticky stacks while filtering those from the body component.
    func divided() -> (body: ExperienceComponent, stickyTop: ExperienceComponent?, stickyBottom: ExperienceComponent?) {
        let (body, stickyTopComponents, stickyBottomComponents) = self.split()

        return (
            // `body` is `nil` only if `self` is sticky, which means there's no root content to be displayed so populate something empty.
            body ?? ExperienceComponent.spacer(SpacerModel(id: UUID(), spacing: nil, style: nil)),
            stickyTopComponents.reduced(),
            stickyBottomComponents.reduced()
        )
    }

    /// Recursively extract sticky stacks while filtering those from the body component.
    private func split() -> (nonSticky: ExperienceComponent?, stickyTop: [ExperienceComponent], stickyBottom: [ExperienceComponent]) {
        var nonStickyComponents: [ExperienceComponent] = []
        var stickyTopComponents: [ExperienceComponent] = []
        var stickyBottomComponents: [ExperienceComponent] = []

        switch self {
        case .stack(let model) where model.sticky == .top:
            return (nil, [self], [])
        case .stack(let model) where model.sticky == .bottom:
            return (nil, [], [self])
        case .stack(let model) where model.sticky == nil:
            model.items.forEach { item in
                let (body, nestedTop, nestedBottom) = item.split()
                if let body = body {
                    nonStickyComponents.append(body)
                }
                stickyTopComponents.append(contentsOf: nestedTop)
                stickyBottomComponents.append(contentsOf: nestedBottom)
            }
            return (
                // Same stack, just with sticky items filtered out
                .stack(StackModel(
                    id: model.id,
                    orientation: model.orientation,
                    distribution: model.distribution,
                    spacing: model.spacing,
                    items: nonStickyComponents,
                    sticky: model.sticky,
                    style: model.style)),
                stickyTopComponents,
                stickyBottomComponents
            )
        case .box(let model):
            model.items.forEach { item in
                let (body, nestedTop, nestedBottom) = item.split()
                if let body = body {
                    nonStickyComponents.append(body)
                }
                stickyTopComponents.append(contentsOf: nestedTop)
                stickyBottomComponents.append(contentsOf: nestedBottom)
            }
            return (
                // Same box, just with sticky items filtered out
                .box(BoxModel(
                    id: model.id,
                    items: nonStickyComponents,
                    style: model.style)),
                stickyTopComponents,
                stickyBottomComponents
            )
        default:
            return (self, [], [])
        }
    }
}

private extension Array where Element == ExperienceComponent {
    /// Reduce multiple components into a single vertical stack.
    func reduced() -> ExperienceComponent? {
        switch count {
        case 0:
            return nil
        case 1:
            return self[0]
        default:
            return ExperienceComponent.stack(ExperienceComponent.StackModel(
                id: UUID(),
                orientation: .vertical,
                distribution: nil,
                spacing: nil,
                items: self,
                sticky: nil,
                style: nil))
        }
    }
}
