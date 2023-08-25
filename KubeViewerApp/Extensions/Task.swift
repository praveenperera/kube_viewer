//
//  Task.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-25.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }

    static func sleep(ms: Double) async throws {
        let duration = UInt64(ms * 1_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
