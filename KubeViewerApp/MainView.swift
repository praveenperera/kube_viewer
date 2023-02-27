//  MainView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-14.
//

import SwiftUI

struct MainView: View {
    struct ScrollId: Hashable, Equatable {
        var tabGroupId: TabGroupId
        var tabId: TabId? = nil
    }

    @StateObject private var model: MainViewModel = .init()
    @State private var hoverRow: UUID?
    @State private var expanded: Bool = true
    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                NavigationSplitView(
                    sidebar: {
                        VStack {
                            ScrollViewReader { proxy in
                                ScrollView {
                                    SearchBar(text: $search)
                                        .padding(.top, 15)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)

                                    ForEach(model.data.tabGroupsFiltered(search: search)) { tabGroup in
                                        DisclosureGroup(isExpanded: $model.tabGroupExpansions[tabGroup.id] ?? true) {
                                            VStack {
                                                ForEach(tabGroup.tabs) { tab in
                                                    SidebarButton(tab: tab, selectedTab: $model.selectedTab)
                                                        .id(ScrollId(tabGroupId: tabGroup.id, tabId: tab.id))
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
                                        .id(ScrollId(tabGroupId: tabGroup.id))
                                        .onReceive(model.$currentFocusRegion, perform: { currentFocusRegion in
                                            withAnimation(.easeIn) {
                                                switch currentFocusRegion {
                                                    case let .sidebarGroup(id: tabGroupId):
                                                        proxy.scrollTo(ScrollId(tabGroupId: tabGroupId))
                                                    case let .inTabGroup(tabGroupId: tabGroupId, tabId: tabId):
                                                        proxy.scrollTo(ScrollId(tabGroupId: tabGroupId, tabId: tabId))
                                                    default:
                                                        ()
                                                }
                                            }
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
                    },
                    detail: { model.tabContentViews[model.selectedTab]! })
            }
        }
        .background(KeyAwareView(onEvent: model.data.handleKeyInput))
        .background(WindowAccessor(window: $model.window).background(BlurWindow()))
        .environmentObject(model)
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
        MainView()
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
