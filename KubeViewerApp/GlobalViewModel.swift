//
//  GlobalViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 3/16/23.
//

import Combine
import Foundation
import SwiftUI

class GlobalViewModel: ObservableObject {
    var data: RustGlobalViewModel
    @RustPublished var clusters: [ClusterId: Cluster]
    @RustPublished var selectedCluster: Cluster?

    init() {
        self.data = RustGlobalViewModel()

        self.clusters = self.data.clusters()
        self._clusters.getter = self.data.clusters

        self.selectedCluster = self.data.selectedCluster()
        self._selectedCluster.getter = self.data.selectedCluster
        self._selectedCluster.setter = {cluster in
            if let cluster = cluster {
                self.data.setSelectedCluster(cluster: cluster)
            }
        }
    }
}

extension Cluster: Identifiable {}

extension Cluster {
    func name() -> String {
        return self.nickname ?? self.id.rawValue
    }
}
