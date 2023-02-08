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
            GeometryReader { geo in
                HStack(spacing: 0) {
                    VStack {
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
                        }
                        .listStyle(PlainListStyle())
                        .navigationTitle(model.tabs[model.selectedTab]!.name)
                    }
                    .overlay(ResizerBar(customSideBarWidth: customSideBarWidth))
                    .gesture(
                        DragGesture()
                            .onChanged { self.customSideBarWidth = $0.location.x }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    switch self.customSideBarWidth {
                                    case .some(let x) where x < 85:
                                        self.customSideBarWidth = 0
                                    case .some(let x) where x < 150:
                                        self.customSideBarWidth = 150
                                    default:
                                        ()
                                    }
                                }
                            }
                    )
                    .frame(width: sidebarWidth(geo))
                    
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
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
        }
    }
}
