//
//  ContentView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct MainView: View {
    let tabList = ["Tab1", "Tab2", "Tab3"].map{Tab(name: $0, content: "This is the content for \($0). A bunch of content would go here")}
    
    @StateObject private var model = ViewModel()
    
    var body: some View {
        NavigationStack {
            TabView(selection: $model.selectedTab) {
                ForEach(model.tabs) { tab in
                    Text(tab.content)
                        .tabItem {
                            Label(tab.name, systemImage: "list.dash")
                        }.onTapGesture {
                            model.selectedTab = tab
                        }.tag(tab)
                    
                }
        }.navigationTitle(model.selectedTab.name)
          }
        .onAppear{ model.tabs = tabList }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
