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

    @State var detailsWidth: CGFloat = 300
    @State var detailsResized: Bool = false
    @State var isDetailsHover = false

    var nodeIsSelected: Bool {
        self.selectedNodes.count == 1
    }

    var selectedNode: Node? {
        if self.selectedNodes.count != 1 {
            return nil
        }

        return self.nodes.first {
            $0.id == self.selectedNodes.first!
        }
    }

    public init(windowId: UUID, globalModel: GlobalModel, mainViewModel: MainViewModel, model: NodeViewModel? = nil) {
        self.windowId = windowId
        self.globalModel = globalModel
        self.mainViewModel = mainViewModel

        self.model = model ??
            globalModel.models[windowId]?.nodes ??
            NodeViewModel(windowId: windowId, selectedCluster: mainViewModel.selectedCluster)

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
        }
        .frame(minWidth: 100)
        .toast(isPresenting: self.$isLoading) {
            AlertToast(displayMode: .alert, type: .loading, title: "Loading")
        }
        .onDisappear {
            Task {
                await self.model.data.stopWatcher()
            }
        }
        .onChange(of: self.mainViewModel.selectedCluster) { newSelectedCluster in
            if let selectedCluster = newSelectedCluster {
                Task {
                    await self.model.data.fetchNodes(selectedCluster: selectedCluster.id)
                }
            }
        }
        .task {
            if let selectedCluster = self.mainViewModel.selectedCluster {
                await self.model.data.fetchNodes(selectedCluster: selectedCluster.id)
            }
        }
        .background(KeyAwareView(onEvent: self.mainViewModel.data.handleKeyInput))
    }

    @ViewBuilder
    var innerBody: some View {
        switch self.model.nodes {
        case .loaded: self.DisplayNodes()
        case .loading, .initial:
            HStack {}

        case .error(let error):
            Text("error: \(error)")
        }
    }

    func DisplayNodes() -> some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                Table(self.nodes, selection: self.$selectedNodes, sortOrder: self.$sortOrder) {
                    TableColumn("Name", value: \.name)
                    TableColumn("Version", value: \.kubeletVersion, comparator: OptionalStringComparator())
                        { Text($0.kubeletVersion ?? "") }
                    TableColumn("Taints", value: \.taints, comparator: CountComparator())
                        { Text(String($0.taints.count)) }
                    TableColumn("Age", value: \.createdAt, comparator: OptionalAgeComparator())
                        { AgeView(createdAt: $0.createdAt, age: $0.age) }
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
                .if(self.nodeIsSelected) { view in
                    view.frame(minWidth: 0, maxWidth: max(200, geo.size.width - self.detailsWidth))
                }

                NodeDetailView(geo: geo,
                               selectedNode: self.selectedNode,
                               detailsWidth: self.$detailsWidth,
                               detailsResized: self.$detailsResized,
                               isDetailsHover: self.$isDetailsHover)
            }
            .onChange(of: geo.size) { _ in
                if !self.detailsResized {
                    self.detailsWidth = geo.size.width / 3.5
                }
            }
            .onAppear {
                self.detailsWidth = geo.size.width / 3.5
            }
        }
    }

    func ConditionsColumnContent(_ node: Node) -> some View {
        ForEach(node.trueConditions(), id: \.self) { condition in
            Text(condition).if(condition == "Ready") { view in
                view.foregroundColor(Color.green).if(self.colorScheme == .light) { view in
                    view.brightness(-0.15)
                }
            }
        }
    }

    func setLoading(_ loading: LoadStatus<[Node]>) {
        switch loading {
        case .loaded, .error:
            self.isLoading = false
            if case .loaded(let nodes) = self.model.nodes {
                self.nodes = nodes
            }
        case .loading, .initial:
            self.selectedNodes = .init()
            self.isLoading = true
        }
    }
}

struct NodeView_Previews: PreviewProvider {
    static var windowId = UUID()
    static var globalModel = GlobalModel()
    static var mainViewModel = MainViewModel(windowId: windowId)
    static var model: NodeViewModel = .init(windowId: windowId)

    static var previews: some View {
        NodeView(windowId: windowId, globalModel: globalModel, mainViewModel: mainViewModel, model: model)
    }
}
