//
//  ViewModel.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import Foundation
import SwiftUI


struct MainTab: Identifiable {
    let id = UUID()
    let name: String
    let content: TabContentView
    var dummyData: Int = 0
}

class ViewModel: ObservableObject {
    @Published var tabs: Dictionary<UUID, MainTab>
    @Published var selectedTab: UUID
    
    static let defaultTabsList: [MainTab] = ["Tab1", "Tab2", "Tab3"].map{ MainTab(name: $0, content: TabContentView(text: "Default content")) }
    static let defaultTabs:  Dictionary<UUID, MainTab> = defaultTabsList.reduce(into: [UUID: MainTab]()) { $0[$1.id] = $1 }
    
    init(sidebarTabs: Dictionary<UUID, MainTab> = ViewModel.defaultTabs) {
        self.tabs = sidebarTabs
        self.selectedTab = sidebarTabs.first!.key
    }
}
