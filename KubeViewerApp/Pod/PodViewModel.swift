//
//  PodViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-07-27.
//

import Combine
import Foundation
import SwiftUI

class PodViewModel: ObservableObject {
    let windowId: UUID
    var data: RustPodViewModel

    @Published var pods: LoadStatus = .initial

    init(windowId: UUID, selectedCluster: Cluster?) {
        self.windowId = windowId
        self.data = RustPodViewModel(windowId: windowId.uuidString)
    }
}
