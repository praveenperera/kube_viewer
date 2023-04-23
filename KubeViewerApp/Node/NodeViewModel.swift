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

    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustNodeViewModel(windowId: windowId.uuidString)

        DispatchQueue.main.async { self.setupCallback() }
    }

    private func setupCallback() {
        self.data.addCallbackListener(responder: self)
    }

    func callback(msg: NodeViewModelMessage) {
        switch msg {
            case .clientLoaded:
                print("Client Loaded")
        }
    }
}
