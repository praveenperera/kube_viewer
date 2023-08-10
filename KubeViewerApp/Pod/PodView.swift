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
        case .loaded: self.DisplayPods(self.pods)
        case .loading, .initial:
            HStack {}

        case .error(let error):
            Text("error: \(error)")
        }
    }

    func DisplayPods(_ pods: [Pod]) -> some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                Table(pods, selection: self.$selectedPods, sortOrder: self.$sortOrder) {
                    TableColumn("Name", value: \.name)
                    TableColumn("Age", value: \.createdAt, comparator: OptionalAgeComparator()) { pod in
                        AgeView(createdAt: pod.createdAt, age: pod.age)
                    }
                    TableColumn("Status", value: \.phase, comparator: RawValueComparator()) { pod in
                        self.DisplayStatus(phase: pod.phase)
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
                .if(self.podIsSelected) { view in
                    view.frame(minWidth: 0, maxWidth: max(200, geo.size.width - self.detailsWidth))
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
        }
    }

    func setLoading(_ loading: LoadStatus<[Pod]>) {
        switch loading {
        case .loaded, .error:
            self.isLoading = false
            if case .loaded(let pods) = self.model.pods {
                self.pods = pods
                self.pods.sort(using: self.sortOrder)
            }
        case .loading, .initial:
            self.selectedPods = .init()
            self.isLoading = true
        }
    }

    @ViewBuilder
    func DisplayStatus(phase: Phase) -> some View {
        switch phase {
        case .failed:
            Text("Failed").foregroundColor(Color.red)
        case .succeeded:
            Text("Succeeded").foregroundColor(Color.green)
                .if(self.colorScheme == .light) { view in
                    view.brightness(-0.10)
                }
        case .pending: Text("Pending")
        case .running:
            Text("Running").foregroundColor(Color.green)
                .if(self.colorScheme == .light) { view in
                    view.brightness(-0.15)
                }
        case .unknown(rawValue: let rawValue):
            Text(rawValue)
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

extension Phase: RawValue {
    func rawValue() -> String {
        switch self {
        case .failed: return "Failed"
        case .succeeded: return "Succeeded"
        case .pending: return "Pending"
        case .running: return "Running"
        case .unknown(rawValue: let rawValue):
            return rawValue
        }
    }
}
