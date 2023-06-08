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
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var globalModel: GlobalModel
    @ObservedObject var mainViewModel: MainViewModel
    @ObservedObject var model: NodeViewModel

    @State var isLoading: Bool = false
    @State var nodes: [Node] = []
    @State private var sortOrder = [KeyPathComparator(\Node.name)]
    @State private var selectedNodes = Set<Node.ID>()

    var selectedNode: Node? {
        if self.selectedNodes.count != 1 {
            return nil
        }

        return self.nodes.first {
            $0.id == self.selectedNodes.first!
        }
    }

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
        .onAppear {
            if let selectedCluster = self.mainViewModel.selectedCluster {
                if selectedCluster != self.model.selectedCluster {
                    self.model.data.fetchNodes(selectedCluster: selectedCluster.id)
                    self.model.selectedCluster = selectedCluster
                } else {
                    self.model.data.refreshNodes(selectedCluster: selectedCluster.id)
                }
            }
        }
        .onDisappear {
            self.model.data.stopWatcher()
        }
    }

    @ViewBuilder
    var innerBody: some View {
        switch self.model.nodes {
        case .loaded: self.DisplayNodes(self.nodes)
        case .loading, .initial:
            HStack {}

        case .error(let error):
            Text("error: \(error)")
        }
    }

    @ViewBuilder
    func DisplayNodes(_ nodes: [Node]) -> some View {
        HStack {
            Table(nodes, selection: self.$selectedNodes, sortOrder: self.$sortOrder) {
                TableColumn("Name", value: \.name)
                TableColumn("Version", value: \.kubeletVersion, comparator: OptionalStringComparator())
                    { Text($0.kubeletVersion ?? "") }
                TableColumn("Taints", value: \.taints, comparator: CountComparator())
                    { Text(String($0.taints.count)) }
                TableColumn("Age", value: \.createdAt, comparator: OptionalAgeComparator())
                    { AgeView(node: $0) }
                TableColumn("Conditions", value: \.conditions, comparator: ConditionsComparator())
                    { self.ConditionsColumnContent($0) }
            }
            .onChange(of: self.sortOrder) { sortOrder in
                switch sortOrder {
                case [KeyPathComparator(\Node.name)]: ()
                case [KeyPathComparator(\Node.createdAt)]: ()
                case let keyPath: self.nodes.sort(using: keyPath)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    VStack {
                        Text("Nodes").font(.headline)
                    }
                }
            }

            self.DetailsView
        }
    }

    @ViewBuilder
    var DetailsView: some View {
        if case .some(let node) = selectedNode {
            VStack {
                Text(node.name)
            }
            .background(.ultraThickMaterial)
        }
    }

    @ViewBuilder
    func ConditionsColumnContent(_ node: Node) -> some View {
        ForEach(node.trueConditions(), id: \.self) { condition in
            Text(condition).if(condition == "Ready") { view in
                view.foregroundColor(Color.green).if(self.colorScheme == .light) { view in
                    view.brightness(-0.15)
                }
            }
        }
    }

    func setLoading(_ loading: NodeLoadStatus) {
        switch loading {
        case .loaded, .error:
            self.isLoading = false
            if case .loaded(let nodes) = self.model.nodes {
                self.nodes = nodes
            }
        case .loading, .initial:
            self.isLoading = true
        }
    }
}

struct AgeView: View {
    let node: Node

    var body: some View {
        switch Date().timeIntervalSince1970 - Double(self.node.createdAt ?? 0) {
        case 0 ... 60:
            TimelineView(.periodic(from: Date(), by: 1)) { _ in
                Text(self.node.age() ?? "")
            }
        case 60 ... (60 * 60):
            TimelineView(.periodic(from: Date(), by: 60)) { _ in
                Text(self.node.age() ?? "")
            }
        default:
            Text(self.node.age() ?? "")
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
