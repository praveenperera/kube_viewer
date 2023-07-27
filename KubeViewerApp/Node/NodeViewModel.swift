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

    @Published var nodes: NodeLoadStatus = .initial

    var selectedCluster: Cluster?

    init(windowId: UUID, selectedCluster: Cluster?) {
        print("loading node view model")
        self.windowId = windowId
        self.data = RustNodeViewModel(windowId: windowId.uuidString)
        self.selectedCluster = selectedCluster

        DispatchQueue.main.async { self.setupCallback() }
    }

    // preview
    #if DEBUG
    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustNodeViewModel.preview(windowId: windowId.uuidString)
        self.selectedCluster = nil

        let nodes = self.selectedCluster.map { self.data.nodes(selectedCluster: $0.id) }
        self.nodes = .loaded(nodes: nodes ?? [])

        DispatchQueue.main.async { self.setupCallback() }
    }
    #endif

    private func setupCallback() {
        Task {
            self.data.addCallbackListener(responder: self)

            if let selectedCluster = self.selectedCluster {
                await self.data.fetchNodes(selectedCluster: selectedCluster.id)
            }
        }
    }

    func callback(message: NodeViewModelMessage) {
        Task {
            await MainActor.run {
                switch message {
                    case .loadingNodes:
                        self.nodes = .loading

                    case let .nodeLoadingFailed(error):
                        self.nodes = .error(error: error)

                    case let .nodesLoaded(nodes: nodes):
                        print("[swift] nodes loaded")
                        self.nodes = .loaded(nodes: nodes)
                }
            }
        }
    }
}
