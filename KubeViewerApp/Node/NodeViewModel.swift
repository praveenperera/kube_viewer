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

    @Published var client: ClientLoadStatus = .initial
    @Published var nodes: NodeLoadStatus = .initial

    var selectedCluster: Cluster?

    init(windowId: UUID, selectedCluster: Cluster?) {
        print("loading node view model")
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
        Task {
            await MainActor.run {
                switch msg {
                    case .loadingClient:
                        self.client = .loading

                    case let .clientLoadingFailed(error):
                        self.client = .error(error: error)

                    case .clientLoaded:
                        print("[swift] client loaded")
                        self.client = .loaded

                    case .loadingNodes:
                        self.nodes = .loading

                    case let .nodeLoadingFailed(error):
                        self.nodes = .error(error: error)

                    case .nodesLoaded:
                        print("[swift] nodes loaded")
                        let nodes = self.selectedCluster.map { self.data.nodes(selectedCluster: $0.id) }
                        self.nodes = .loaded(nodes: nodes ?? [])
                }
            }
        }
    }
}
