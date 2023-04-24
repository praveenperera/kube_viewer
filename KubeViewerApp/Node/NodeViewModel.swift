//
//  NodeViewModel.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 4/22/23.
//

import Foundation
import SwiftUI

class NodeViewModel: ObservableObject, NodeViewModelCallback {
    let windowId: UUID
    var data: RustNodeViewModel

    @State var clientLoaded = false

    @RustPublished var nodes: [Node]

    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustNodeViewModel(windowId: windowId.uuidString)

        self.nodes = self.data.nodes()
        self._nodes.getter = self.data.nodes

        DispatchQueue.main.async { self.setupCallback() }
    }

    private func setupCallback() {
        self.data.addCallbackListener(responder: self)
    }

    func callback(msg: NodeViewModelMessage) {
        switch msg {
            case .clientLoaded:
                DispatchQueue.main.async {
                    self.clientLoaded = true
                }
            case .loadedNodes:
                DispatchQueue.main.async {
                    self.clientLoaded = true
                }
        }
    }
}
