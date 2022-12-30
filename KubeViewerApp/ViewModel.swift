//
//  ViewModel.swift
//  KubeViewerApp
//
//  Created by Thavish Perera on 2022-12-29.
//

import Foundation
import SwiftUI


struct Tab: Identifiable {
    let id = UUID().uuidString
    let name: String
    let content: String
    var dummyData: Int = 0
}

class ViewModel: ObservableObject {
    @Published var tabs: [Tab]
    
    static let defaultTabs = ["Tab1", "Tab2", "Tab3"].map{Tab(name: $0, content: "default content")}
    
    init(sidebarTabs: [Tab] = ViewModel.defaultTabs) {
        self.tabs = sidebarTabs
    }
}
