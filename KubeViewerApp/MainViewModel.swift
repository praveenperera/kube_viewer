//
//  ViewModel.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import Combine
import Foundation
import SwiftUI

class MainViewModel: ObservableObject {
    var data: RustMainViewModel = .init()
    var tabs: [Tab]
    var tabsMap: [TabId: Tab]
    var tabGroups: [TabGroup]

    @Published var window: NSWindow?
    @Published var selectedMainTab: NSWindow?

    @Published var tabContentViews: [TabId: TabContentView]
    @Published var tabViewModels: [TabId: TabViewModel]
    @RustPublished var tabGroupExpantions: [TabGroupId: Bool]
    @RustPublished var selectedTab: TabId

    init() {
        self.tabs = self.data.tabs()
        self.tabsMap = self.data.tabsMap()
        self.tabGroups = self.data.tabGroups()

        self.tabContentViews = self.tabsMap.mapValues { tab in TabContentView(text: tab.name) }
        self.tabViewModels = self.tabsMap.mapValues { _ in TabViewModel() }

        self.tabGroupExpantions = self.data.tabGroupExpansions()
        self._tabGroupExpantions.getter = self.data.tabGroupExpansions

        self.selectedTab = self.data.selectedTab()
    }
}

struct Previews_MainViewModel_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}

extension Tab: Identifiable {}
extension TabGroup: Identifiable {}
