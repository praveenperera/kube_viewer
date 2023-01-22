//
//  ContentView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct ContentView: View {
    let tabList = ["Tab1", "Tab2", "Tab3"].map{Tab(name: $0, content: "This is the content for \($0). A bunch of content would go here")}
    
    @StateObject private var model = ViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(model.tabs.indices, id: \.self) {idx in
                    let item = model.tabs[idx]
                    NavigationLink(item.name, destination: TabView(tab: $model.tabs[idx]))
                }
            }
            .listStyle(.sidebar)
        }
        .onAppear{ model.tabs = tabList }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
