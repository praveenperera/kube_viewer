//  MainView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-14.
//

import SwiftUI

enum FocusArea {
    case search, sidebar, content
}

struct MainView: View {
    @StateObject private var model: MainViewModel = .init()
    @StateObject var keyHandlerModel: KeyHandlerModel = .init()

    @State private var hoverRow: UUID?
    @State private var expanded: Bool = true
    @State private var search: String = ""

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                NavigationSplitView(
                    sidebar: {
                        VStack {
                            ScrollView {
                                SearchBar(text: $search).padding(.top, 15)
                                ForEach(model.data.tabGroupsFiltered(search: search)) { tabGroup in
                                    DisclosureGroup(isExpanded: $model.tabGroupExpansions[tabGroup.id] ?? true) {
                                        VStack {
                                            ForEach(tabGroup.tabs) { tab in
                                                SidebarButton(tab: tab, selectedTab: $model.selectedTab)
                                            }
                                        }
                                        .padding(.leading, 5)
                                    } label: {
                                        SidebarTitle(name: tabGroup.name)
                                    }
                                    .disclosureGroupStyle(SidebarDisclosureGroupStyle())
                                    .padding(.top, 5)
                                    .overlay {
                                        if model.currentFocusRegion == .sidebarGroup(id: tabGroup.id) {
                                            RoundedRectangle(cornerRadius: 4).stroke(Color.red)
                                        }
                                    }
                                }

                                .padding(.vertical, 10)

                                Spacer()
                            }
                            .navigationTitle(model.tabsMap[model.selectedTab]?.name ?? "Unknown tab")
                            .padding(.horizontal, 20)
                        }

                        Divider()

                        HStack {
                            Button("Main Cluster") {}
                        }.padding(.top, 8).padding(.bottom, 15)
                    },
                    detail: { model.tabContentViews[model.selectedTab]! })
            }
        }
        .background(KeyAwareView(onEvent: { key in
            model.data.handleKeyInput(keyInput: key)
        }))
        .onChange(of: model.currentFocusRegion) { curr in
            debugPrint("current focus region changed", curr)
        }
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
