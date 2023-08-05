//
//  OptionalStringComparator.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 6/8/23.
//

import Foundation

struct OptionalStringComparator: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: String?, _ rhs: String?) -> ComparisonResult {
        let result: ComparisonResult
        switch (lhs, rhs) {
        case (nil, nil): result = .orderedSame
        case (.some, nil): result = .orderedDescending
        case (nil, .some): result = .orderedAscending
        case let (lhs?, rhs?): result = lhs.localizedCompare(rhs)
        }

        return order == .forward ? result : result.reversed
    }
}

struct OptionalIntComparator<T: BinaryInteger>: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        let result: ComparisonResult
        switch (lhs, rhs) {
        case (nil, nil): result = .orderedSame
        case (.some, nil): result = .orderedDescending
        case (nil, .some): result = .orderedAscending
        case let (.some(lhs), .some(rhs)): result = IntComparator().compare(lhs, rhs)
        }

        return order == .forward ? result : result.reversed
    }
}

struct CountComparator<T>: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: [T], _ rhs: [T]) -> ComparisonResult {
        let result = IntComparator().compare(lhs.count, rhs.count)
        return order == .forward ? result : result.reversed
    }
}

struct IntComparator<T: BinaryInteger>: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: T, _ rhs: T) -> ComparisonResult {
        var result: ComparisonResult = .orderedSame

        if lhs == rhs {
            result = .orderedSame
        }

        if lhs > rhs {
            result = .orderedAscending
        }

        if rhs > lhs {
            result = .orderedDescending
        }

        return order == .forward ? result : result.reversed
    }
}

protocol RawValue {
    func rawValue() -> String
}

struct RawValueComparator<T: RawValue>: SortComparator {
    var order: SortOrder = .forward

    func compare(_ lhs: T, _ rhs: T) -> ComparisonResult {
        lhs.rawValue().localizedCompare(rhs.rawValue())
    }
}

extension ComparisonResult {
    var reversed: ComparisonResult {
        switch self {
        case .orderedAscending: return .orderedDescending
        case .orderedSame: return .orderedSame
        case .orderedDescending: return .orderedAscending
        }
    }
}
