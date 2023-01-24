//
//  ContentView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct MainView: View {
    @StateObject private var model = MainViewModel()
    
    var body: some View {
        NavigationStack {
            TabView(selection: $model.selectedTab) {
                ForEach(Array(model.tabs.values)) { tab in
                    tab.content
                        .tabItem {
                            Label(tab.name, systemImage: "list.dash")
                        }.onTapGesture {
                            model.selectedTab = tab.id
                        }.tag(tab.id)
                    
                }
            }.navigationTitle(model.tabs[model.selectedTab]!.name)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
