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
            GeometryReader {geo in
                HStack(spacing: 0) {
                    List {
                        ForEach(model.tabs.values.sorted(by: { s1, s2 in s1.name < s2.name })) { tab in
                            Button {
                                model.selectedTab = tab.id
                            }
                            label: {
                                HStack {
                                    Text(">")
                                    Text(tab.name)
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                        .listStyle(.sidebar)
                    }.navigationTitle(model.tabs[model.selectedTab]!.name)
                        .frame(width: geo.size.width * (1/6))
                    
                    model.tabs[model.selectedTab]!.content.padding(10)
                    
                    Spacer()
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
