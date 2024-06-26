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
    let windowId: UUID
    private var listener: Listener?
    let data: RustMainViewModel
    let tabs: [Tab]
    let tabsMap: [TabId: Tab]

    @Published var selectedMainTab: NSWindow?
    @Published var tabContentViews: [TabId: TabContentView]
    @Published var tabViewModels: [TabId: TabViewModel]
    @Published var search: String

    @RustPublished var tabGroupExpansions: [TabGroupId: Bool]
    @RustPublished var selectedTab: TabId
    @RustPublished var currentFocusRegion: FocusRegion
    @RustPublished var selectedCluster: Cluster?

    init(windowId: UUID) {
        self.windowId = windowId
        self.data = RustMainViewModel(windowId: windowId.uuidString)
        self.tabs = self.data.tabs()
        self.tabsMap = self.data.tabsMap()
        self.search = ""
        self.listener = nil

        self.tabContentViews = self.tabsMap.mapValues { tab in TabContentView(text: tab.name) }
        self.tabViewModels = self.tabsMap.mapValues { _ in TabViewModel() }

        self.tabGroupExpansions = self.data.tabGroupExpansions()
        self._tabGroupExpansions.getter = self.data.tabGroupExpansions
        self._tabGroupExpansions.setter = self.data.setTabGroupExpansions

        self.selectedTab = self.data.selectedTab()
        self._selectedTab.getter = self.data.selectedTab
        self._selectedTab.setter = self.data.setSelectedTab

        self.currentFocusRegion = self.data.currentFocusRegion()
        self._currentFocusRegion.getter = self.data.currentFocusRegion
        self._currentFocusRegion.setter = self.data.setCurrentFocusRegion

        self.selectedCluster = self.data.selectedCluster()
        self._selectedCluster.getter = self.data.selectedCluster
        self._selectedCluster.setter = { cluster in
            if let cluster = cluster {
                self.data.setSelectedCluster(cluster: cluster)
            }
        }

        DispatchQueue.main.async { self.setupListener() }
    }

    var filteredTabGroups: [TabGroup] {
        self.data.tabGroupsFiltered(search: self.search)
    }

    private func setupListener() {
        if self.listener == nil {
            self.listener = Listener(callback: self.receiveListenerUpdate)
            self.data.addUpdateListener(updater: self.listener!)
        }
    }

    private func receiveListenerUpdate(field: MainViewModelField) {
        Task {
            await MainActor.run {
                switch field {
                    case let .currentFocusRegion(focusRegion: focusRegion):
                        self.currentFocusRegion = focusRegion
                    case let .selectedTab(tabId: tabId):
                        self.selectedTab = tabId
                    case let .tabGroupExpansions(expansions: expansions):
                        self.tabGroupExpansions = expansions
                }
            }
        }
    }
}

extension MainViewModel {
    class Listener: MainViewModelUpdater {
        var callback: (MainViewModelField) -> ()

        init(callback: @escaping (MainViewModelField) -> ()) {
            self.callback = callback
        }

        func update(field: MainViewModelField) {
            self.callback(field)
        }
    }
}

struct Previews_MainViewModel_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}

extension Tab: Identifiable {}
extension TabGroup: Identifiable {}
public extension FocusRegion {
    func hash(into hasher: inout Hasher) {
        let h = FocusRegionHasher()
        let hash = h.hash(value: self)
        hasher.combine(hash)
    }
}
