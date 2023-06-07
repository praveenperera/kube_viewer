//
//  Node.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 6/7/23.
//

import Foundation

extension Node: Identifiable {
    func trueConditions() -> [String] {
        return self.conditions.filter { $0.status == "True" }.map { $0.name }
    }

    func age() -> String? {
        let dateFormatter = ISO8601DateFormatter()

        guard let timestamp = self.createdAt else {
            return nil
        }

        let createdAt = Date(timeIntervalSince1970: Double(timestamp))

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
