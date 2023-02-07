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
        customSideBarWidth ?? max(150, geo.size.width * (1 / 8))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    List {
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
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                    }
                    .listStyle(PlainListStyle())
                    .padding(EdgeInsets(top: 0, leading: -10, bottom: -10, trailing: -10))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .navigationTitle(model.tabs[model.selectedTab]!.name)
                    .frame(width: sidebarWidth(geo))
                    
                    // resize bar
                    ResizerBar(sideBarWidth: sidebarWidth(geo), customSideBarWidth: $customSideBarWidth)
                    
                    model.tabs[model.selectedTab]!.content.padding(10)
                    
                    Text(String(model.window?.tabbedWindows?.count ?? 0))
                    
                    Spacer()
                }
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
    var sideBarWidth: CGFloat
    @Binding var customSideBarWidth: CGFloat?
    
    func width() -> CGFloat {
        if let x = customSideBarWidth, x == 0 {
            return 0
        } else {
            return 2
        }
    }
    
    var body: some View {
        Rectangle().frame(width: width())
            .gesture(
                DragGesture()
                    .onChanged {
                        self.customSideBarWidth = sideBarWidth + $0.translation.width
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            if let customSideBarWidth = self.customSideBarWidth, customSideBarWidth < 150 {
                                self.customSideBarWidth = 0
                            }
                        }
                    }
            ).onHover { hovering in
                DispatchQueue.main.async {
                    if hovering {
                        NSCursor.resizeLeftRight.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }.offset(x: -1)
            .foregroundColor(Color.secondary.opacity(1))
    }
}
