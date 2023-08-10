//
//  Pod.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-03.
//

import Foundation

extension Pod: Identifiable, CreatedAt, AgeTimestamp {
    func totalRestarts() -> Int32 {
        // replace with rust function when logs are cleared up
        // podRestartCount(pod: self)

        self.containers.map(\.restartCount).reduce(0, +)
    }
}
