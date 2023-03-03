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
    var listener: Listener?
    var data: RustMainViewModel
    var tabs: [Tab]
    var tabsMap: [TabId: Tab]
    var tabGroups: [TabGroup]

    @Published var window: NSWindow?
    @Published var selectedMainTab: NSWindow?

    @Published var tabContentViews: [TabId: TabContentView]
    @Published var tabViewModels: [TabId: TabViewModel]

    @RustPublished var tabGroupExpansions: [TabGroupId: Bool]
    @RustPublished var selectedTab: TabId
    @RustPublished var currentFocusRegion: FocusRegion

    init() {
        self.data = RustMainViewModel(windowId: UUID().uuidString)
        self.tabs = self.data.tabs()
        self.tabsMap = self.data.tabsMap()
        self.tabGroups = self.data.tabGroups()

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

        DispatchQueue.main.async { self.setupListener() }
    }

    private func setupListener() {
        if self.listener == nil {
            self.listener = Listener(callback: self.receiveListenerUpdate)
            self.data.addUpdateListener(listener: self.listener!)
        }
    }

    private func receiveListenerUpdate(field: MainViewModelField) {
        Task {
            await MainActor.run {
                switch field {
                case .currentFocusRegion:
                    self.currentFocusRegion = self.data.currentFocusRegion()
                case .selectedTab:
                    self.selectedTab = self.data.selectedTab()
                case .tabGroupExpansions:
                    self.tabGroupExpansions = self.data.tabGroupExpansions()
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
