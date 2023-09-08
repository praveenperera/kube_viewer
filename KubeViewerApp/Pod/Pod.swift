//
//  Pod.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-03.
//

import Foundation

extension Pod: Identifiable, CreatedAt, AgeTimestamp {
    func totalRestarts() -> Int32 {
        self.containers.map { c in c.restartCount }.reduce(0, +)
    }

    var logCmd: String {
        podLogCmd(namespace: self.namespace, podId: self.id)
    }

    var containerExecCmd: String {
        podExecCmd(namespace: self.namespace, podId: self.id)
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
