//
//  NodeComparators.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 6/8/23.
//

import Foundation

struct OptionalAgeComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: Int64?, _ rhs: Int64?) -> ComparisonResult {
        var result = OptionalIntComparator().compare(lhs, rhs)
        result = result.reversed

        return order == .forward ? result : result.reversed
    }
}

struct ConditionsComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: [NodeCondition], _ rhs: [NodeCondition]) -> ComparisonResult {
        var result: ComparisonResult = .orderedAscending

        let lhs = lhs.filter { $0.status == "True" }.map { $0.name }
        let rhs = rhs.filter { $0.status == "True" }.map { $0.name }

        if lhs == rhs {
            return order == .forward ? result : result.reversed
        }

        if lhs.count < rhs.count && lhs.last == "Ready" {
            result = .orderedDescending
        } else {
            result = .orderedAscending
        }

        return order == .forward ? result : result.reversed
    }
}
