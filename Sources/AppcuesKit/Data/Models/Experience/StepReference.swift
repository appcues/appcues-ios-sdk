//
//  StepReference.swift
//  AppcuesKit
//
//  Created by Matt on 2022-03-08.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal enum StepReference: Equatable {
    case index(Int)
    case offset(Int)
    case stepID(UUID)

    static func == (lhs: StepReference, rhs: StepReference) -> Bool {
        switch (lhs, rhs) {
        case let (.index(index1), .index(index2)):
            return index1 == index2
        case let (.offset(offset1), .offset(offset2)):
            return offset1 == offset2
        case let (.stepID(id1), .stepID(id2)):
            return id1 == id2
        default:
            return false
        }
    }

    func resolve(experience: Experience, currentIndex: Experience.StepIndex) -> Experience.StepIndex? {
        switch self {
        case .index(let index):
            return experience.stepIndices[safe: index]
        case .offset(let offset):
            guard let currentArrayIndex = experience.stepIndices.firstIndex(where: { $0 == currentIndex }) else { return nil }
            return experience.stepIndices[safe: currentArrayIndex + offset]
        case .stepID(let stepID):
            return experience.stepIndex(for: stepID)
        }
    }
}

extension Experience {
    struct StepIndex: Equatable, CustomStringConvertible {
        static var initial = StepIndex(group: 0, item: 0)

        var group: Int
        var item: Int

        var description: String { "\(group),\(item)" }

        init(group: Int, item: Int) {
            self.group = group
            self.item = item
        }

        init?(description: String) {
            let parts = description.split(separator: ",").compactMap { Int($0) }
            guard parts.count == 2 else { return nil }

            self.group = parts[0]
            self.item = parts[1]
        }
    }

    var stepIndices: [StepIndex] {
        steps.enumerated().flatMap { groupOffset, element in
            element.items.enumerated().map { stepOffset, _ in
                StepIndex(group: groupOffset, item: stepOffset)
            }
        }
    }

    func stepIndex(for id: UUID) -> StepIndex? {
        for (groupOffset, element) in steps.enumerated() {
            if element.id == id {
                return StepIndex(group: groupOffset, item: 0)
            }

            for (stepOffset, step) in element.items.enumerated() where step.id == id {
                return StepIndex(group: groupOffset, item: stepOffset)
            }
        }
        return nil
    }

    func step(at stepIndex: StepIndex) -> Step.Child? {
        steps[safe: stepIndex.group]?.items[safe: stepIndex.item]
    }
}

private extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
