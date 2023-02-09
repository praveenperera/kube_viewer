//
//  ContentView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct SideBarButtonLabel: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.white)
    }
}

struct MainView: View {
    @StateObject private var model: MainViewModel = .init()
    @State private var hoverRow: UUID?
    @State private var customSideBarWidth: CGFloat?

    func sidebarWidth(_ geo: GeometryProxy) -> CGFloat {
        max(0, customSideBarWidth ?? max(150, geo.size.width * (1 / 8)))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                NavigationSplitView(
                    sidebar: {
                        ForEach(model.tabs.values.sorted(by: { s1, s2 in s1.name < s2.name })) { tab in
                            Button(action: { model.selectedTab = tab.id }) {
                                HStack {
                                    Text(">")
                                    Text(tab.name)
                                }
                            }
                            .onTapGesture {
                                model.selectedTab = tab.id
                            }
                            .onHover { hovering in
                                hoverRow = hovering ? tab.id : nil
                                DispatchQueue.main.async {
                                    if hovering {
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                            }
                        }
                        .navigationTitle(model.tabs[model.selectedTab]!.name)
                    },

                    detail: { model.tabs[model.selectedTab]!.content })
            }
        }.background(WindowAccessor(window: $model.window))
            .background(BlurWindow())
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
