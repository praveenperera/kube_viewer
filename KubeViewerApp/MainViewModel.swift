//
//  ViewModel.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import Foundation
import SwiftUI


struct SideBarTab: Identifiable {
    let id = UUID()
    let name: String
    let content: TabContentView
    let viewModel: TabViewModel
    var dummyData: Int = 0
}


class MainViewModel: ObservableObject {
    @Published var tabs: Dictionary<UUID, SideBarTab>
    @Published var selectedTab: UUID
    @Published var selectedMainTab: NSWindow?
    
    static let defaultTabsList: [SideBarTab] = ["Tab1", "Tab2", "Tab3"].map{ SideBarTab(name: $0, content: TabContentView(text: "Default content for \($0)"), viewModel: TabViewModel.init()) }
    static let defaultTabs:  Dictionary<UUID, SideBarTab> = defaultTabsList.reduce(into: [UUID: SideBarTab]()) { $0[$1.id] = $1 }
    
    init(tabs: Dictionary<UUID, SideBarTab> = MainViewModel.defaultTabs) {
        self.tabs = tabs
        self.selectedTab = tabs.first!.key
    }
}
