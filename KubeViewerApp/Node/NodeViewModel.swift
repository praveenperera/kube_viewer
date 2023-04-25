//
//  NodeViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 4/22/23.
//

import Combine
import Foundation
import SwiftUI

class NodeViewModel: ObservableObject, NodeViewModelCallback {
    let windowId: UUID
    var data: RustNodeViewModel
    var clientLoaded = false
    var selectedCluster: Cluster?

    var nodes: [Node]? {
        self.selectedCluster.map { self.data.nodes(selectedCluster: $0.id) }
    }

    init(windowId: UUID, selectedCluster: Cluster?) {
        self.windowId = windowId
        self.data = RustNodeViewModel(windowId: windowId.uuidString)
        self.selectedCluster = selectedCluster

        DispatchQueue.main.async { self.setupCallback() }
    }

    private func setupCallback() {
        self.data.addCallbackListener(responder: self)

        if let selectedCluster = self.selectedCluster {
            self.data.fetchNodes(selectedCluster: selectedCluster.id)
        }
    }

    func callback(msg: NodeViewModelMessage) {
        switch msg {
            case .clientLoaded:
                print("client loaded loaded")
                DispatchQueue.main.async {
                    self.clientLoaded = true
                }
            case .nodesLoaded:
                print("nodes loaded")
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
        }
    }
}
