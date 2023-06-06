//
//  NodeView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 4/22/23.
//

import AlertToast
import SwiftUI

struct NodeView: View {
    let windowId: UUID
    @ObservedObject var globalModel: GlobalModel
    @ObservedObject var mainViewModel: MainViewModel
    @ObservedObject var model: NodeViewModel

    @State var isLoading: Bool = true

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
        VStack {
            self.innerBody
                .onChange(of: self.model.nodes, perform: self.setLoading)
                .onChange(of: self.mainViewModel.selectedCluster) { newSelectedCluster in
                    if let selectedCluster = newSelectedCluster {
                        self.model.data.fetchNodes(selectedCluster: selectedCluster.id)
                    }
                }
        }
        .frame(minWidth: 100)
        .toast(isPresenting: self.$isLoading) {
            AlertToast(displayMode: .alert, type: .loading, title: "Loading")
        }
    }

    @ViewBuilder
    var innerBody: some View {
        switch self.model.nodes {
        case .loaded(let nodes):
            Table(nodes) {
                TableColumn("Name", value: \.name)
                TableColumn("Kubelet Version") { node in Text(node.kubeletVersion ?? "") }
                TableColumn("Conditions", value: \.name)
            }
        case .loading, .initial:
            HStack {}

        case .error(let error):
            Text("error: \(error)")
        }
    }

    func setLoading(_ loading: NodeLoadStatus) {
        switch loading {
        case .loaded, .error:
            self.isLoading = false
        case .loading, .initial:
            self.isLoading = true
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
