//
//  NodeView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 4/22/23.
//

import SwiftUI

struct NodeView: View {
    let windowId: UUID
    @ObservedObject var globalModel: GlobalModel
    @ObservedObject var model: NodeViewModel

    public init(windowId: UUID, globalModel: GlobalModel) {
        self.windowId = windowId
        self.globalModel = globalModel
        self.model = NodeViewModel(windowId: windowId)
    }

    var body: some View {
        Text(model.path ?? "Hello word here are my nodes!")
    }
}

struct NodeView_Previews: PreviewProvider {
    static var windowId = UUID()
    static var globalModel = GlobalModel()

    static var previews: some View {
        NodeView(windowId: windowId, globalModel: globalModel)
    }
}
