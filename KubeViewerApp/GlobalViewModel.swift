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
    @RustPublished var clusters: [ClusterId: Cluster];

    init() {
        self.data = RustGlobalViewModel()
        
        self.clusters = self.data.clusters()
        self._clusters.getter = self.data.clusters
    }
}

extension Cluster: Identifiable {}
