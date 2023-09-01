//
//  PodView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 4/22/23.
//

import AlertToast
import SwiftUI

struct PodView: View {
    let windowId: UUID
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var globalModel: GlobalModel
    @ObservedObject var mainViewModel: MainViewModel
    @ObservedObject var model: PodViewModel

    @State var isLoading: Bool = false
    @State var pods: [Pod] = []

    @State private var sortOrder = [KeyPathComparator(\Pod.name)]
    @State private var selectedPods = Set<Pod.ID>()

    @State var detailsWidth: CGFloat = 300
    @State var detailsResized: Bool = false
    @State var isDetailsHover = false

    @State var isConfirmingDeletePod: Bool = false
    @State var podIdsToDelete: Set<Pod.ID> = []

    var podIsSelected: Bool {
        self.selectedPods.count == 1
    }

    var selectedPod: Pod? {
        if self.selectedPods.count != 1 {
            return nil
        }

        return self.pods.first {
            $0.id == self.selectedPods.first!
        }
    }

    public init(windowId: UUID, globalModel: GlobalModel, mainViewModel: MainViewModel, model: PodViewModel? = nil) {
        self.windowId = windowId
        self.globalModel = globalModel
        self.mainViewModel = mainViewModel

        self.model = model ?? globalModel.models[windowId]?.pods ?? PodViewModel(windowId: windowId)

        if let viewModels = globalModel.models[windowId],
           viewModels.pods == nil
        {
            $globalModel.models[windowId].wrappedValue!.pods = self.model
        }
    }

    var body: some View {
        VStack {
            self.innerBody
                .onChange(of: self.model.pods, perform: self.setLoading)
        }
        .frame(minWidth: 150)
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
                    await self.model.getDataAndSetupWatcher(selectedCluster.id)
                }
            }
        }
        .task {
            if let selectedCluster = self.mainViewModel.selectedCluster {
                await self.model.getDataAndSetupWatcher(selectedCluster.id)
            }
        }
        .background(KeyAwareView(onEvent: self.mainViewModel.data.handleKeyInput))
    }

    @ViewBuilder
    var innerBody: some View {
        switch self.model.pods {
        case .loaded: self.DisplayPods()
        case .loading, .initial:
            HStack {}

        case .error(let error):
            Text("error: \(error)")
        }
    }

    func DisplayPods() -> some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                Table(of: Pod.self, selection: self.$selectedPods, sortOrder: self.$sortOrder) {
                    TableColumn("Name", value: \.name) {
                        NameView(name: $0.name)
                    }
                    TableColumn("Namespace", value: \.namespace)
                    TableColumn("Containers", value: \.containers, comparator: CountComparator()) { pod in
                        ContainerView(containers: pod.containers)
                    }
                    TableColumn("Restarts", value: \.containers, comparator: RestartComparator()) { pod in
                        Text(String(pod.totalRestarts()))
                    }
                    TableColumn("QoS", value: \.qosClass, comparator: OptionalStringComparator()) { pod in
                        Text(pod.qosClass ?? "Unknown")
                    }
                    TableColumn("Age", value: \.createdAt, comparator: OptionalAgeComparator()) {
                        AgeView(createdAt: $0.createdAt, age: $0.age)
                    }
                    TableColumn("Status", value: \.phase, comparator: RawValueComparator()) { pod in
                        PodPhaseView(phase: pod.phase, isSelected: self.selectedPods.contains(pod.id))
                    }
                } rows: {
                    ForEach(self.pods) { pod in
                        TableRow(pod)
                            .contextMenu {
                                Button(role: .destructive) {
                                    self.isConfirmingDeletePod = true
                                    if self.selectedPods.contains(pod.id) {
                                        self.podIdsToDelete = self.selectedPods
                                    } else {
                                        self.podIdsToDelete = [pod.id]
                                    }
                                } label: {
                                    Text("Delete")
                                }
                            }
                    }
                }
                .onChange(of: self.sortOrder) { sortOrder in
                    self.pods.sort(using: sortOrder)
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        VStack {
                            Text("Pods").font(.headline)
                        }
                    }
                }

                PodDetailView(geo: geo,
                              selectedPod: self.selectedPod,
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
            .confirmationDialog(
                self.podIdsToDelete.count > 1 ? "Are you sure you want to delete these \(self.podIdsToDelete.count) pods?" : "Are you sure you want to delete this pod?",
                isPresented: self.$isConfirmingDeletePod, presenting: self.podIdsToDelete
            ) { _ in
                Button(role: .destructive) {
                    if let selectedCluster = self.mainViewModel.selectedCluster,
                       let podId = self.podIdsToDelete.first
                    {
                        Task {
                            print("[swift] Deleting pod", podId)
                            await self.model.data.deletePod(selectedCluster: selectedCluster.id, podId: podId)
                        }
                    }
                } label: {
                    Text("Delete")
                }

                Button("Cancel", role: .cancel) {
                    self.podIdsToDelete = []
                }
            } message: { _ in
                VStack {
                    PodDeleteConfirmMessage(podIds: self.podIdsToDelete)
                }
            }
        }
    }

    func setLoading(_ loading: LoadStatus<[Pod]>) {
        switch loading {
        case .loaded, .error:
            self.isLoading = false
            if case .loaded(var pods) = self.model.pods {
                pods.sort(using: self.sortOrder)
                self.pods = pods
            }
        case .initial:
            self.selectedPods = .init()
            self.isLoading = true

        case .loading:
            self.isLoading = true
        }
    }
}

struct PodView_Previews: PreviewProvider {
    static var windowId = UUID()
    static var globalModel = GlobalModel()
    static var mainViewModel = MainViewModel(windowId: windowId)
    static var model: PodViewModel = .init(windowId: windowId)

    static var previews: some View {
        PodView(windowId: windowId, globalModel: globalModel, mainViewModel: mainViewModel, model: model)
    }
}
