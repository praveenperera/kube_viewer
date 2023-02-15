//
//  MainView.swift
//  KubeViewerApp
//
//  Created by Praveen Perera on 2023-02-14.
//

import SwiftUI

struct MainView: View {
    @StateObject private var model: MainViewModel = .init()
    @State private var hoverRow: UUID?
    @State private var expanded: Bool = true

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                NavigationSplitView(
                    sidebar: {
                        VStack {
                            List {
                                ForEach(model.tabGroups) { tabGroup in
                                    DisclosureGroup(isExpanded: $model.tabGroupExpansions[tabGroup.id] ?? true, content: {
                                        VStack {
                                            ForEach(tabGroup.tabs) { tab in
                                                SidebarButton(tab: tab, selectedTab: $model.selectedTab)
                                            }
                                        }
                                        .padding(.leading, 5)
                                    }, label: {
                                        SidebarTitle(name: tabGroup.name)
                                    })
                                    .disclosureGroupStyle(SidebarDisclosureGroup())
                                    .padding(.top, 5)
                                }
                            }
                        }
                        .padding(.leading, 10)
                        .navigationTitle(model.tabsMap[model.selectedTab]?.name ?? "Unknown tab")
                    },
                    detail: { model.tabContentViews[model.selectedTab]! })
            }
        }.background(WindowAccessor(window: $model.window).background(BlurWindow()))
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

struct SidebarButton: View {
    var tab: Tab
    @Binding var selectedTab: TabId
    @State private var isHover = false

    var body: some View {
        HStack {
            Button(action: { selectedTab = tab.id }) {
                Label {
                    Text(tab.name)
                } icon: {
                    Image(systemName: tab.icon)
                        .foregroundColor(Color.blue)
                }
            }.buttonStyle(.plain).padding(.leading, 10)
                .if(isHover) { view in
                    view.scaleEffect(1.015)
                }.animation(.default, value: isHover)

            Spacer()
        }
        .padding([.top, .bottom], 5)
        .frame(maxWidth: .infinity)
        .if(selectedTab == tab.id) { view in
            view.background(Color.secondary.opacity(0.25))
                .background(.ultraThinMaterial)
        }
        .if(isHover) { view in
            view.background(Color.secondary.opacity(0.10))
                .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring()) {
                self.selectedTab = tab.id
            }
        }
        .whenHovered { hovering in
            self.isHover = hovering
        }
        .padding(.trailing, 15)
    }
}

struct SidebarTitle: View {
    var name: String

    var body: some View {
        Text(name)
            .foregroundColor(.secondary)
            .font(.system(size: 11, weight: .semibold))
    }
}

struct SidebarDisclosureGroup: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    configuration.label.animation(nil, value: configuration.isExpanded)
                    Spacer()
                    Text(configuration.isExpanded ? "hide" : "show")
                        .foregroundColor(.accentColor)
                        .font(.caption.lowercaseSmallCaps())
                        .animation(nil, value: configuration.isExpanded)
                }
                .padding(.bottom, 0)
                .contentShape(Rectangle())
            }
            .padding(.bottom, 0)
            .buttonStyle(.plain)

            if configuration.isExpanded {
                configuration.content
            }
        }
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
