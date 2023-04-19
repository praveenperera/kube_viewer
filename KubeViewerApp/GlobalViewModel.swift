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
    @RustPublished var selected_cluster: ClusterId?

    init() {
        self.data = RustGlobalViewModel()

        self.clusters = self.data.clusters()
        self._clusters.getter = self.data.clusters

        self.selected_cluster = self.data.selected_cluster()
        self._selected_cluster.getter = self.data.selected_cluster
        self._selected_cluster.setter = self.data.set_selected_cluster
    }
}

extension Cluster: Identifiable {}

extension Cluster {
    func name() -> String {
        return self.nickname ?? self.id.rawValue
    }
}
