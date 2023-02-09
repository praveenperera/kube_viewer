//
//  MainView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct MainView: View {
    @StateObject private var model: MainViewModel = .init()
    @State private var hoverRow: UUID?
    @State private var customSideBarWidth: CGFloat?
    @State private var expanded: Bool = true

    func sidebarWidth(_ geo: GeometryProxy) -> CGFloat {
        max(0, customSideBarWidth ?? max(150, geo.size.width * (1 / 8)))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                NavigationSplitView(
                    sidebar: {
                        VStack {
                            DisclosureGroup(isExpanded: $expanded, content: {
                                VStack {
                                    ForEach(model.tabGroups.general.tabs) { tab in
                                        SidebarButton(selectedTab: $model.selectedTab, tab: tab)
                                    }
                                }
                                .padding([.top, .leading], 5)
                            }, label: {
                                SidebarTitle()

                            })
                            Spacer()
                        }
                        .padding(.leading, 10)
                        .navigationTitle(model.tabs[model.selectedTab]!.name)
                    },
                    detail: { model.tabs[model.selectedTab]!.content })
            }
        }.background(WindowAccessor(window: $model.window).background(BlurWindow()))
    }

    func tabBackgroundColor(_ tab: SideBarTab) -> Color {
        if tab.id == model.selectedTab {
            return Theme.Color.blue900
        }

        return hoverRow == tab.id ? Theme.Color.blue800 : Theme.Color.blue600
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

struct ResizerBar: View {
    var customSideBarWidth: CGFloat?

    func width() -> CGFloat {
        if let x = customSideBarWidth, x == 0 {
            return 2
        } else {
            return 5
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Rectangle().frame(width: width())
                .foregroundColor(Color.red.opacity(0))
                .onHover { hovering in
                    DispatchQueue.main.async {
                        if hovering {
                            customSideBarWidth == 0 ? NSCursor.resizeRight.push()
                                : NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
        }
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}

struct SidebarButton: View {
    @Binding var selectedTab: UUID
    @State private var isHover = false

    var tab: SideBarTab

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
                .onHover { hovering in
                    isHover = hovering
                }

            Spacer()
        }

        .padding([.top, .bottom], 5)
        .if(selectedTab == tab.id) { view in
            view.background(Color.secondary.opacity(0.25))
                .background(.ultraThinMaterial)
        }
        .if(isHover) { view in
            view.background(Color.secondary.opacity(0.25))
                .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .frame(maxWidth: .infinity)
        .padding(.trailing, 15)
        .onTapGesture {
            selectedTab = tab.id
        }
    }
}

struct SidebarTitle: View {
    var body: some View {
        HStack {
            Text("General")
                .foregroundColor(.secondary)
                .font(.system(size: 11, weight: .semibold))
        }
    }
}
