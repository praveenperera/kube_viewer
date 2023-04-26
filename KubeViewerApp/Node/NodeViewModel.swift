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

    @RustPublished var nodes: [Node]?

    init(windowId: UUID, selectedCluster: Cluster?) {
        print("loading node view model")
        self.windowId = windowId
        self.data = RustNodeViewModel(windowId: windowId.uuidString)
        self.selectedCluster = selectedCluster

        self.nodes = nil
        self._nodes.getter = {
            self.selectedCluster.map { self.data.nodes(selectedCluster: $0.id) }
        }

        DispatchQueue.main.async { self.setupCallback() }
    }

    private func setupCallback() {
        self.data.addCallbackListener(responder: self)

        if let selectedCluster = self.selectedCluster {
            self.data.fetchNodes(selectedCluster: selectedCluster.id)
        }
    }

    func callback(msg: NodeViewModelMessage) {
        Task {
            await MainActor.run {
                switch msg {
                    case .clientLoaded:
                        print("[swift] client loaded")
                        self.clientLoaded = true
                    case .nodesLoaded:
                        print("[swift] nodes loaded")
                        self.nodes = self.selectedCluster.map { self.data.nodes(selectedCluster: $0.id) }
                }
            }
        }
    }
}
