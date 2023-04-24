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
    @ObservedObject var mainViewModel: MainViewModel
    @ObservedObject var model: NodeViewModel

    public init(windowId: UUID, globalModel: GlobalModel, mainViewModel: MainViewModel) {
        self.windowId = windowId
        self.globalModel = globalModel
        self.mainViewModel = mainViewModel
        self.model = globalModel.models[windowId]?.nodes ?? NodeViewModel(windowId: windowId)

        if let viewModels = globalModel.models[windowId],
           viewModels.nodes == nil
        {
            $globalModel.models[windowId].wrappedValue!.nodes = self.model
        }
    }

    var body: some View {
        if let nodes = self.model.nodes {
            ForEach(nodes) { node in
                Text(node.name)
            }.onReceive(self.mainViewModel.$selectedCluster, perform: { selectedCluster in
                print("onReceive")
                self.model.nodes(selectedCluster: selectedCluster!.id)
            })
        }
    }
}

struct NodeView_Previews: PreviewProvider {
    static var windowId = UUID()
    static var globalModel = GlobalModel()
    static var mainViewModel = MainViewModel(windowId: windowId)

    static var previews: some View {
        NodeView(windowId: windowId, globalModel: globalModel, mainViewModel: mainViewModel)
    }
}

extension Node: Identifiable {}
