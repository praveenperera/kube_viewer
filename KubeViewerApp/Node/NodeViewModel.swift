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

    init(windowId: UUID, selectedCluster: Cluster?) {
        self.windowId = windowId
        self.data = RustNodeViewModel(windowId: windowId.uuidString)

        DispatchQueue.main.async { self.setupCallback() }
    }

    // preview
    #if DEBUG
    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustNodeViewModel.preview(windowId: windowId.uuidString)

        self.nodes = .loaded(nodes: [])

        DispatchQueue.main.async { self.setupCallback() }
    }
    #endif

    private func setupCallback() {
        Task {
            await self.data.addCallbackListener(responder: self)
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
