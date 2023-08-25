//
//  Pod.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-03.
//

import Foundation

extension Pod: Identifiable, CreatedAt, AgeTimestamp {
    func totalRestarts() -> Int32 {
        podRestartCount(pod: self)
    }
}

extension Phase: RawValue {
    func rawValue() -> String {
        switch self {
        case .failed: return "Failed"
        case .succeeded: return "Succeeded"
        case .pending: return "Pending"
        case .running: return "Running"
        case .unknown(rawValue: let rawValue):
            return rawValue
        }
    }
}

extension Container: Identifiable {}
