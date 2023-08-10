//
//  PodComparators.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-10.
//

import Foundation

struct RestartComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: [Container], _ rhs: [Container]) -> ComparisonResult {
        var result: ComparisonResult = .orderedAscending

        let lhs = lhs.map(\.restartCount).reduce(0, +)
        let rhs = rhs.map(\.restartCount).reduce(0, +)

        result = IntComparator().compare(lhs, rhs)

        return order == .forward ? result : result.reversed
    }
}
