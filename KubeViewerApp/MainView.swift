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
                            DisclosureGroup(isExpanded: $expanded, content: {
                                VStack {
                                    ForEach(model.tabs) { tab in
                                        SidebarButton(selectedTab: $model.selectedTab, tab: tab)
                                    }
                                }
                                .padding([.top, .leading], 5)
                            }, label: {
                                SidebarTitle(type: .general)
                            })

                            DisclosureGroup(isExpanded: $expanded, content: {
                                VStack {
                                    ForEach(model.tabGroups.workloads.tabs) { tab in
                                        SidebarButton(selectedTab: $model.selectedTab, tab: tab)
                                    }
                                }
                                .padding([.top, .leading], 5)
                            }, label: {
                                SidebarTitle(type: .workloads)
                            })
                        }
                        .padding(.leading, 10)
                        .navigationTitle(model.tabs[model.selectedTab]!.name)
                    },
                    detail: { model.tabs[model.selectedTab]!.content })
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
    @Binding var selectedTab: UUID
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
    var body: some View {
        HStack {
            Text(type.title())
                .foregroundColor(.secondary)
                .font(.system(size: 11, weight: .semibold))
        }
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
