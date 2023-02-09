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
    let icon: String
    let content: TabContentView
    let viewModel: TabViewModel
    var dummyData: Int = 0
}

enum TabGroupType {
    case general
}

extension TabGroupType {
    func name() -> String {
        switch self {
        case .general:
            return "General"
        }
    }
}

struct TabGroup {
    let name: TabGroupType
    let tabs: [SideBarTab]
}

struct TabGroups {
    let general: TabGroup
}

let defaultTabGroups = TabGroups(general:
    TabGroup(name: .general, tabs: [
        SideBarTab(name: "Cluster", icon: "steeringwheel", content: TabContentView(text: "I am in cluster content"), viewModel: TabViewModel()),
        SideBarTab(name: "Nodes", icon: "server.rack", content: TabContentView(text: "I am in nodes content"), viewModel: TabViewModel()),
    ]))

class MainViewModel: ObservableObject {
    @Published var window: NSWindow?
    @Published var tabGroups: TabGroups
    @Published var selectedTab: UUID
    @Published var selectedMainTab: NSWindow?

    init() {
        self.tabGroups = defaultTabGroups
        self.selectedTab = defaultTabGroups.general.tabs[0].id
    }

    var tabs: [UUID: SideBarTab] {
        self.tabGroups.general.tabs.reduce(into: [UUID: SideBarTab]()) {
            $0[$1.id] = $1
        }
    }
}

struct Previews_MainViewModel_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
