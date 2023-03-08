//  MainView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-14.
//

import SwiftUI

struct MainView: View {
    let windowId: UUID
    @EnvironmentObject var globalModel: GlobalModel
    @ObservedObject var model: MainViewModel
    @State private var hoverRow: UUID?
    @State private var expanded: Bool = true
    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            NavigationSplitView(
                sidebar: { Sidebar
                    .navigationSplitViewColumnWidth(min: 200, ideal: 260)
                },
                detail: {
                    HStack {
                        model.tabContentViews[model.selectedTab]!
                        Text(model.windowId.uuidString)
                    }

                })
        }
        .background(KeyAwareView(onEvent: model.data.handleKeyInput))
        .background(WindowAccessor(window: $model.window).background(BlurWindow()))
        .environmentObject(model)
        .if(model.window != nil) { view in
            view.onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: model.window)) { _ in
                DispatchQueue.main.async {
                    globalModel.windowClosing(self.windowId)
                }
            }
        }
    }

    @ViewBuilder
    var Sidebar: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    SearchBar(text: $search)
                        .padding(.top, 15)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .id(FocusRegion.sidebarSearch)

                    ForEach(model.data.tabGroupsFiltered(search: search)) { tabGroup in
                        DisclosureGroup(isExpanded: $model.tabGroupExpansions[tabGroup.id] ?? true) {
                            VStack {
                                ForEach(tabGroup.tabs) { tab in
                                    SidebarButton(tab: tab, selectedTab: $model.selectedTab)
                                        .id(FocusRegion.inTabGroup(tabGroupId: tabGroup.id, tabId: tab.id))
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
                            switch model.currentFocusRegion {
                            case let .sidebarGroup(id: id) where id == tabGroup.id,
                                 let .inTabGroup(tabGroupId: id, tabId: _) where id == tabGroup.id:
                                StandardFocusRing()
                            default:
                                Color.clear
                            }
                        }
                        .id(FocusRegion.sidebarGroup(id: tabGroup.id))
                        .onReceive(model.$currentFocusRegion, perform: { currentFocusRegion in
                            proxy.scrollTo(currentFocusRegion)
                        })
                    }

                    Spacer()
                }
                .navigationTitle(model.tabsMap[model.selectedTab]?.name ?? "Unknown tab")
                .padding(.top, 5)
                .padding(.horizontal, 8)
            }
        }

        Divider()

        ClusterSelection
    }

    var ClusterSelection: some View {
        HStack {
            Button("Main Cluster") {}
        }
        .overlay {
            if model.currentFocusRegion == .clusterSelection {
                StandardFocusRing()
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, 7)
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
        let uuid = UUID()
        MainView(windowId: uuid, model: MainViewModel(windowId: uuid))
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
