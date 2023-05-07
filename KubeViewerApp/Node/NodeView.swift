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

        self.model = globalModel.models[windowId]?.nodes ?? NodeViewModel(windowId: windowId, selectedCluster: mainViewModel.selectedCluster)

        if let viewModels = globalModel.models[windowId],
           viewModels.nodes == nil
        {
            $globalModel.models[windowId].wrappedValue!.nodes = self.model
        }
    }

    var body: some View {
        switch self.model.nodes {
        case .loaded(let nodes):
            ForEach(nodes) { node in
                Text(node.name)
            }
            .onChange(of: self.mainViewModel.selectedCluster) { newSelectedCluster in
                if let selectedCluster = newSelectedCluster {
                    self.model.data.fetchNodes(selectedCluster: selectedCluster.id)
                }
            }
        case .loading, .initial:
            Text("loading...")
        case .error(let error):
            Text("error: \(error)")
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
