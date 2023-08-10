//  MainView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-14.
//

import SwiftUI

struct MainView: View {
    let windowId: UUID
    @ObservedObject var globalModel: GlobalModel
    @ObservedObject var model: MainViewModel
    @StateObject var globalViewModel: GlobalViewModel = .init()

    @State private var windowIsLoaded: Bool = false
    @State private var hoverRow: UUID?
    @State private var expanded: Bool = true
    @State private var search: String = ""
    @State private var window: NSWindow?

    private func sortedClusterIds() -> [ClusterId] {
        let keys = self.globalViewModel.clusters.keys
        return keys.sorted(by: { $0.rawValue < $1.rawValue })
    }

    public init(windowId: Binding<UUID?>, globalModel: GlobalModel) {
        self.windowId = windowId.wrappedValue ?? UUID()
        self.globalModel = globalModel
        self.model = globalModel.mainWindowModel(self.windowId) ?? MainViewModel(windowId: self.windowId)

        // save model in global models
        if globalModel.mainWindowModel(self.windowId) == nil {
            var models = globalModel.models

            if models[self.windowId] == nil {
                models[self.windowId] = ViewModels(main: self.model)
            }

            globalModel.models = models
        }
    }

    var body: some View {
        NavigationStack {
            NavigationSplitView(
                sidebar: { self.Sidebar
                    .navigationSplitViewColumnWidth(min: 200, ideal: 260)
                },
                detail: {
                    self.TabContent
                }
            )
        }
        .background(KeyAwareView(onEvent: self.model.data.handleKeyInput))
        .background(WindowAccessor(window: self.$window).background(BlurWindow()))
        .environmentObject(self.model)
        .onAppear {
            self.globalModel.windowOpened(self.windowId)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: self.window)) { _ in
            if self.window != nil {
                DispatchQueue.main.async {
                    self.globalModel.windowClosing(self.windowId)
                }
            }
        }
        .onChange(of: self.window) { newWindow in
            if newWindow != nil {
                self.windowIsLoaded = true
            }
        }
    }

    @ViewBuilder
    var TabContent: some View {
        switch self.model.selectedTab {
        case TabId.nodes:
            NodeView(windowId: self.windowId, globalModel: self.globalModel, mainViewModel: self.model)
        case TabId.pods:
            PodView(windowId: self.windowId, globalModel: self.globalModel, mainViewModel: self.model)
        case TabId.deployments:
            DeploymentView()
        default:
            self.model.tabContentViews[self.model.selectedTab]!
            Text(self.model.windowId.uuidString)
        }
    }

    @ViewBuilder
    var Sidebar: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    SearchBar(text: self.$search)
                        .padding(.top, 15)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .id(FocusRegion.sidebarSearch)

                    ForEach(self.model.data.tabGroupsFiltered(search: self.search)) { tabGroup in
                        DisclosureGroup(isExpanded: self.$model.tabGroupExpansions[tabGroup.id] ?? true) {
                            VStack {
                                if self.windowIsLoaded {
                                    ForEach(tabGroup.tabs) { tab in
                                        SidebarButton(tab: tab, selectedTab: self.$model.selectedTab)
                                            .id(FocusRegion.inTabGroup(tabGroupId: tabGroup.id, tabId: tab.id))
                                            .transition(.opacity)
                                    }
                                }
                            }
                            .padding(.leading, 5)
                        } label: {
                            SidebarTitle(name: tabGroup.name)
                        }
                        .disclosureGroupStyle(SidebarDisclosureGroupStyle())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .overlay {
                            switch self.model.currentFocusRegion {
                            case let .sidebarGroup(id: id) where id == tabGroup.id,
                                 let .inTabGroup(tabGroupId: id, tabId: _) where id == tabGroup.id:
                                StandardFocusRing()
                            default:
                                Color.clear
                            }
                        }
                        .id(FocusRegion.sidebarGroup(id: tabGroup.id))
                        .onReceive(self.model.$currentFocusRegion, perform: { currentFocusRegion in
                            proxy.scrollTo(currentFocusRegion)
                        })
                    }

                    Spacer()
                }
                .navigationTitle(self.model.tabsMap[self.model.selectedTab]?.name ?? "Unknown tab")
                .padding(.top, 5)
                .padding(.horizontal, 8)
            }
        }

        Divider()

        self.ClusterSelection
    }

    var ClusterSelection: some View {
        VStack {
            Menu(
                content: {
                    ForEach(self.sortedClusterIds(), id: \.self) { clusterId in
                        let cluster = self.globalViewModel.clusters[clusterId]!
                        ClusterSelectionButton(action: { self.model.selectedCluster = cluster }, cluster: cluster)
                    }
                },
                label: {
                    Label(self.model.selectedCluster?.name() ?? "Select a cluster ...", systemImage: "chevron.down")
                }
            )
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .overlay {
                if self.model.currentFocusRegion == .clusterSelection {
                    StandardFocusRing()
                }
            }
            .menuStyle(CustomMenuStyle())
        }.padding(.bottom, 7)
    }
}

struct ClusterSelectionButton: View {
    let action: () -> ()
    let cluster: Cluster

    var body: some View {
        switch self.cluster.loadStatus {
        case .initial, .loading:
            Button(action: self.action) {
                Text(self.cluster.name())
                    .foregroundColor(Color.primary.opacity(0.75))
            }

        case .loaded:
            Button(action: self.action) {
                Text(self.cluster.name()).bold()
            }

        case .error:
            Button(action: {}) {
                Text(self.cluster.name())
                    .foregroundColor(Color.red.opacity(0.7))
            }.disabled(true)
        }
    }
}

struct CustomMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .menuIndicator(.hidden)
            .menuStyle(BorderlessButtonMenuStyle())
            .buttonStyle(BorderedButtonStyle())
    }
}

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(windowId: Binding.constant(nil), globalModel: GlobalModel())
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
