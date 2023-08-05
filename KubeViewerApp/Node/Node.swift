//
//  Node.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 6/7/23.
//

import Foundation

extension Node: Identifiable, CreatedAt, AgeTimestamp {
    func trueConditions() -> [String] {
        return self.conditions.filter { $0.status == "True" }.map { $0.name }
    }
}
