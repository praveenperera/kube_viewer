//
//  TabView.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import SwiftUI

struct TabView: View {
    @Binding var tab: Tab
    
    var body: some View {
        VStack {
            Spacer()
            Text(tab.content)
            Spacer()
            Text(String(tab.dummyData))
            Button("Increment Dummy Data") {
                tab.dummyData += 1
            }
            Spacer()
        }
        .navigationTitle(tab.name)
    }
}

//struct TabView_Previews: PreviewProvider {
//    static var previews: some View {
//        @Binding var tab: Tab = Tab(name: "Test Tab", content: "test content")
//        TabView(tab: tab)
//    }
//}
