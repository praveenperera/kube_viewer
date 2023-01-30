//
//  ContentView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct SideBarButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(30)
            .foregroundColor(.white)
            .clipShape(Rectangle())
    }
}

struct MainView: View {
    @StateObject private var model = MainViewModel();
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
                            .background(hoverRow == tab.id ? Theme.Color.blue800 : Theme.Color.blue600)
                            .buttonStyle(SideBarButton())
                            .onHover{ _ in hoverRow = tab.id }
                        }.listRowBackground(Color(.red))
                            .listRowInsets(EdgeInsets(top: -20, leading: 0, bottom: -20, trailing: 0))
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
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
