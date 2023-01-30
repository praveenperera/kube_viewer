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
            .clipShape(Rectangle())
    }
}

struct MainView: View {
    @ObservedObject var model: MainViewModel;
    @State private var hoverRow: UUID?;
    
    var body: some View {
        NavigationStack {
            GeometryReader {geo in
                HStack(spacing: 0) {
                    List {
                        ForEach(model.tabs.values.sorted(by: { s1, s2 in s1.name < s2.name })) { tab in
                            Button(action: {model.selectedTab = tab.id} ) {
                                HStack {
                                    Text(">")
                                    Text(tab.name)
                                }.frame(maxWidth: .infinity)
                            }
                            .background(tabBackgroundColor(tab))
                            .buttonStyle(SideBarButtonLabel())
                            .onTapGesture {
                                model.selectedTab = tab.id
                            }
                            .onHover{ hovering in
                                hoverRow = hovering ? tab.id : nil
                                DispatchQueue.main.async {
                                    if (hovering) {
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
                    .clipShape(Rectangle())
                    .navigationTitle(model.tabs[model.selectedTab]!.name)
                    .frame(maxWidth: max(250, geo.size.width * (1/6)))
                    
                    model.tabs[model.selectedTab]!.content.padding(10)
                    
                    Spacer()}
            }
        }
    }
    
    func tabBackgroundColor(_ tab: SideBarTab) -> Color {
        if (tab.id == model.selectedTab) {
            return Theme.Color.blue900
        }
        
        return hoverRow == tab.id ? Theme.Color.blue800 : Theme.Color.blue600
    }
}



struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(model: MainViewModel())
    }
}