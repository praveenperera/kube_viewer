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
    let viewModel: TabViewModel
    var dummyData: Int = 0
}

class MainViewModel: ObservableObject {
    @Published var tabs: Dictionary<UUID, MainTab>
    @Published var selectedTab: UUID
    
    static let defaultTabsList: [MainTab] = ["Tab1", "Tab2", "Tab3"].map{ MainTab(name: $0, content: TabContentView(text: "Default content for \($0)"), viewModel: TabViewModel.init()) }
    static let defaultTabs:  Dictionary<UUID, MainTab> = defaultTabsList.reduce(into: [UUID: MainTab]()) { $0[$1.id] = $1 }
    
    init(tabs: Dictionary<UUID, MainTab> = MainViewModel.defaultTabs) {
        self.tabs = tabs
        self.selectedTab = tabs.first!.key
    }
}
