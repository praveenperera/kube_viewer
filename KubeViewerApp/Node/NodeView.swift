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
        self.model = globalModel.models[windowId]?.nodes ?? NodeViewModel(windowId: windowId)

        if let viewModels = globalModel.models[windowId],
           viewModels.nodes == nil
        {
            $globalModel.models[windowId].wrappedValue!.nodes = self.model
        }
    }

    var body: some View {
        ForEach(self.model.nodes) { node in
            Text(node.name)
        }
    }
}

struct NodeView_Previews: PreviewProvider {
    static var windowId = UUID()
    static var globalModel = GlobalModel()

    static var previews: some View {
        NodeView(windowId: windowId, globalModel: globalModel)
    }
}

extension Node: Identifiable {}
