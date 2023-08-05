//
//  Age.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-08-04.
//

import Foundation

protocol CreatedAt {
    var createdAt: Int64? { get }
}

protocol AgeTimestamp: CreatedAt {
    func age() -> String?
    func createdAtTimestamp() -> String?
}

extension AgeTimestamp {
    func age() -> String? {
        guard let timestamp = self.createdAt else {
            return nil
        }

        let createdAt = Date(timeIntervalSince1970: Double(timestamp))

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    func createdAtTimestamp() -> String? {
        guard let timestamp = self.createdAt else {
            return nil
        }

        let createdAt = Date(timeIntervalSince1970: Double(timestamp))
        return createdAt.formatted()
    }
}
